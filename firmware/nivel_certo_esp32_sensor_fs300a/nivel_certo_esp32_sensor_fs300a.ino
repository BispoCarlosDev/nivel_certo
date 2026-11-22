// ======================================================================
//  Nível Certo - ESP32 (Arduino IDE)
//  Sensor ultrassônico SR04M-2 (nível) + sensor de vazão FS300A 3/4" (ENTRADA)
//  Envia uma leitura por minuto para o Supabase.
//
//  O Wi-Fi NÃO fica no código: o usuário informa a rede pelo aplicativo,
//  que envia o nome e a senha por Bluetooth. A placa guarda na memória.
//    - Sem Wi-Fi salvo (ou se a rede não conectar): modo de configuração
//      por Bluetooth (anuncia como "NC-<código do dispositivo>").
//    - Para apagar o Wi-Fi salvo: segure o botão BOOT por 5 s com a placa ligada.
//
//  Placa no Arduino IDE: "ESP32 Dev Module" (ou a sua)
//  Se der "Sketch too big": Ferramentas > Partition Scheme > "Huge APP".
//  Bibliotecas: nenhuma extra (WiFi, BLE, Preferences e HTTPClient já vêm
//  com o pacote "esp32 by Espressif Systems").
// ======================================================================
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <Preferences.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

// ---------------------------- CONFIGURAÇÃO ----------------------------
const char* SUPABASE_URL = "https://ngepvftlssgcqodxkgye.supabase.co";
const char* SUPABASE_PUBLISHABLE_KEY = "sb_publishable_fuiNXjuLAfXOAjx6lESA3Q_xOtrn-Qp";

// Chave SECRETA DO DISPOSITIVO (a que você gerou no SQL, não é a chave do Supabase)
const char* CHAVE_DISPOSITIVO = "COLE_AQUI_A_CHAVE_DO_DISPOSITIVO";

// Identificadores do serviço Bluetooth de configuração (iguais aos do aplicativo)
const char* UUID_SERVICO = "7f1a0001-5c1e-4b7a-9d3a-2c4e1f0a6b10";
const char* UUID_CONFIG  = "7f1a0002-5c1e-4b7a-9d3a-2c4e1f0a6b10";
const char* UUID_STATUS  = "7f1a0003-5c1e-4b7a-9d3a-2c4e1f0a6b10";

// Pinos
const int PINO_TRIG = 18;   // saída: RX do módulo SR04M-2 (liga direto)
const int PINO_ECHO = 19;   // entrada: TX do módulo SR04M-2 (passa pelo divisor de resistores)
const int PINO_FLUXO = 21;  // entrada: fio amarelo do FS300A (passa pelo divisor de resistores)

// Pulsos por litro do sensor de vazão.
// FS300A (3/4"): F = 5,5 x vazão (L/min)  ->  5,5 x 60 = ~330 pulsos por litro.
// (YF-S201 de 1/2" seria 450.) Para calibrar: passe 10 L por um balde, veja os
// "pulsos acumulados" no Serial Monitor e divida por 10.
const float PULSOS_POR_LITRO = 330.0;

const unsigned long INTERVALO_ENVIO_MS = 60UL * 1000UL;  // 1 minuto
const int TENTATIVAS_DISTANCIA = 15;                     // tentativas por leitura (o módulo falha às vezes)
const int PAUSA_ENTRE_TENTATIVAS_MS = 150;               // pausa entre tentativas
// ----------------------------------------------------------------------

volatile unsigned long pulsos = 0;
portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;

void IRAM_ATTR contaPulso() {
  portENTER_CRITICAL_ISR(&mux);
  pulsos++;
  portEXIT_CRITICAL_ISR(&mux);
}

String identificador;
Preferences prefs;
String wifiSsid, wifiSenha;              // Wi-Fi salvo na memória da placa
unsigned long ultimoEnvio = 0;
volatile unsigned long ultimoSucesso = 0;  // instante do último envio bem-sucedido
const unsigned long LIMITE_SEM_ENVIO_MS = 10UL * 60UL * 1000UL;  // reinicia se ficar 10 min sem enviar
unsigned long pulsosNoUltimoEnvio = 0;  // pulsos já enviados com sucesso
bool primeiroEnvio = true;              // 1º envio após ligar: sem vazão (ver README)

// Mede a distância em cm. Retorna -1 se falhar.
float medirUmaVez() {
  digitalWrite(PINO_TRIG, LOW);
  delayMicroseconds(5);
  digitalWrite(PINO_TRIG, HIGH);
  delayMicroseconds(100);  // este módulo responde bem a pulsos de ~100 us (15 us falhava)
  digitalWrite(PINO_TRIG, LOW);
  unsigned long dur = pulseIn(PINO_ECHO, HIGH, 40000UL);  // até ~6,8 m
  if (dur == 0) return -1;
  return dur * 0.0343f / 2.0f;
}

// Tenta medir várias vezes e devolve a mediana das que deram certo.
// Retorna -1 se menos de 3 tentativas funcionarem.
float medirDistanciaCm() {
  float v[TENTATIVAS_DISTANCIA];
  int n = 0;
  for (int i = 0; i < TENTATIVAS_DISTANCIA; i++) {
    float d = medirUmaVez();
    if (d > 0) v[n++] = d;
    delay(PAUSA_ENTRE_TENTATIVAS_MS);
  }
  if (n < 3) return -1;
  for (int i = 1; i < n; i++) {           // ordenação simples
    float x = v[i];
    int j = i - 1;
    while (j >= 0 && v[j] > x) { v[j + 1] = v[j]; j--; }
    v[j + 1] = x;
  }
  return v[n / 2];
}

// Para o teste na tela: tenta até 6 vezes e para na primeira que funcionar.
float medirRapido() {
  for (int i = 0; i < 6; i++) {
    float d = medirUmaVez();
    if (d > 0) return d;
    delay(PAUSA_ENTRE_TENTATIVAS_MS);
  }
  return -1;
}

// Tenta conectar em uma rede; devolve true se conseguiu.
bool tentaWiFi(const String& ssid, const String& senha, unsigned long limiteMs) {
  WiFi.disconnect();
  delay(200);
  WiFi.begin(ssid.c_str(), senha.c_str());
  unsigned long ini = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - ini < limiteMs) {
    delay(500);
    Serial.print(".");
  }
  return WiFi.status() == WL_CONNECTED;
}

void conectaWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  Serial.print("Conectando ao WiFi");
  Serial.println(tentaWiFi(wifiSsid, wifiSenha, 20000) ? " ok" : " falhou");
}

// Segurar BOOT por 5 s apaga o Wi-Fi salvo e reinicia em modo de configuração.
void verificaBotaoReset() {
  static unsigned long inicio = 0;
  if (digitalRead(0) == LOW) {
    if (inicio == 0) inicio = millis();
    if (millis() - inicio > 5000) {
      prefs.clear();
      Serial.println("Wi-Fi apagado. Reiniciando...");
      delay(300);
      ESP.restart();
    }
  } else {
    inicio = 0;
  }
}

// ---------------------- Configuração por Bluetooth ----------------------
BLECharacteristic* statusChar = nullptr;
volatile bool configPendente = false;
String novoSsid, novaSenha;

void defineStatus(const char* texto) {
  if (statusChar) statusChar->setValue((uint8_t*)texto, strlen(texto));
}

// O app envia "nome-da-rede\nsenha\nchave-do-dispositivo"
class ConfigCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) override {
    String dados = String(c->getValue().c_str());
    int primeira = dados.indexOf('\n');
    int ultima = dados.lastIndexOf('\n');
    if (primeira < 0 || ultima == primeira) {
      defineStatus("formato_invalido");
      return;
    }
    String ssid = dados.substring(0, primeira);
    String senha = dados.substring(primeira + 1, ultima);
    String chave = dados.substring(ultima + 1);

    if (chave != String(CHAVE_DISPOSITIVO)) {
      defineStatus("chave_invalida");
      return;
    }
    if (ssid.length() < 1 || ssid.length() > 32 ||
        (senha.length() != 0 && (senha.length() < 8 || senha.length() > 63))) {
      defineStatus("formato_invalido");
      return;
    }
    novoSsid = ssid;
    novaSenha = senha;
    configPendente = true;
    defineStatus("recebido");
  }
};

void iniciaBle() {
  String nome = "NC-" + identificador;
  BLEDevice::init(nome.c_str());
  BLEDevice::setMTU(517);
  BLEServer* servidor = BLEDevice::createServer();
  BLEService* servico = servidor->createService(UUID_SERVICO);
  BLECharacteristic* config =
      servico->createCharacteristic(UUID_CONFIG, BLECharacteristic::PROPERTY_WRITE);
  config->setCallbacks(new ConfigCallbacks());
  statusChar =
      servico->createCharacteristic(UUID_STATUS, BLECharacteristic::PROPERTY_READ);
  defineStatus("aguardando");
  servico->start();

  BLEAdvertising* anuncio = BLEDevice::getAdvertising();
  anuncio->addServiceUUID(UUID_SERVICO);
  anuncio->setScanResponse(true);
  BLEDevice::startAdvertising();
  Serial.print("Bluetooth ligado como: ");
  Serial.println(nome);
}

// Fica aqui até o app enviar um Wi-Fi que funcione (aí reinicia).
// Se já havia um Wi-Fi salvo, tenta de novo a cada 60 s (ex.: roteador desligado).
void modoConfiguracao() {
  Serial.println("Modo de configuracao: aguardando o aplicativo (Bluetooth)...");
  iniciaBle();
  unsigned long ultimaTentativa = millis();
  for (;;) {
    verificaBotaoReset();

    if (configPendente) {
      configPendente = false;
      defineStatus("conectando");
      Serial.printf("Testando Wi-Fi '%s'", novoSsid.c_str());
      if (tentaWiFi(novoSsid, novaSenha, 20000)) {
        prefs.putString("ssid", novoSsid);
        prefs.putString("pass", novaSenha);
        defineStatus("ok");
        Serial.println(" ok. Salvo. Reiniciando...");
        delay(5000);  // dá tempo do app ler o resultado
        ESP.restart();
      }
      Serial.println(" falhou");
      WiFi.disconnect();
      defineStatus("erro_wifi");
      ultimaTentativa = millis();
    }

    if (wifiSsid.length() > 0 && millis() - ultimaTentativa > 60000) {
      ultimaTentativa = millis();
      Serial.print("Tentando o Wi-Fi salvo");
      if (tentaWiFi(wifiSsid, wifiSenha, 15000)) {
        Serial.println(" ok. Reiniciando...");
        ESP.restart();
      }
      Serial.println(" falhou");
      WiFi.disconnect();
    }
    delay(100);
  }
}

// Tarefa de segurança: se ficar muito tempo sem enviar (travou, Wi-Fi preso...),
// reinicia a placa sozinha.
void tarefaVigia(void*) {
  for (;;) {
    vTaskDelay(10000 / portTICK_PERIOD_MS);
    if (millis() - ultimoSucesso > LIMITE_SEM_ENVIO_MS) {
      Serial.println("Sem enviar ha muito tempo. Reiniciando...");
      delay(200);
      ESP.restart();
    }
  }
}

bool enviar(float distanciaCm, bool temVazao, float litros, float vazaoLpm) {
  WiFiClientSecure cliente;
  cliente.setInsecure();  // protótipo: não valida o certificado (ver observações)
  cliente.setTimeout(15);  // segundos
  HTTPClient http;
  String url = String(SUPABASE_URL) + "/rest/v1/rpc/registrar_leitura";
  if (!http.begin(cliente, url)) return false;
  http.setTimeout(15000);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", SUPABASE_PUBLISHABLE_KEY);

  String corpo = "{\"p_identificador\":\"" + identificador + "\"";
  corpo += ",\"p_chave\":\"" + String(CHAVE_DISPOSITIVO) + "\"";
  corpo += ",\"p_distancia_cm\":" + (distanciaCm > 0 ? String(distanciaCm, 1) : String("null"));
  corpo += ",\"p_vazao_lpm\":" + (temVazao ? String(vazaoLpm, 2) : String("null"));
  corpo += ",\"p_volume_periodo_l\":" + (temVazao ? String(litros, 3) : String("null"));
  corpo += "}";

  int codigo = http.POST(corpo);
  Serial.printf("HTTP %d\n", codigo);
  if (codigo < 0) Serial.println(http.errorToString(codigo));
  else if (codigo >= 300) Serial.println(http.getString());
  http.end();
  return codigo >= 200 && codigo < 300;
}

void setup() {
  Serial.begin(115200);
  delay(500);
  pinMode(PINO_TRIG, OUTPUT);
  digitalWrite(PINO_TRIG, LOW);
  pinMode(PINO_ECHO, INPUT);
  pinMode(PINO_FLUXO, INPUT);
  pinMode(0, INPUT_PULLUP);  // botão BOOT
  attachInterrupt(digitalPinToInterrupt(PINO_FLUXO), contaPulso, FALLING);

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(false);
  // MAC lido direto da memória da placa (não depende do Wi-Fi já estar ligado)
  uint64_t mac = ESP.getEfuseMac();
  char macTxt[18];
  snprintf(macTxt, sizeof(macTxt), "%02X:%02X:%02X:%02X:%02X:%02X",
           (uint8_t)(mac), (uint8_t)(mac >> 8), (uint8_t)(mac >> 16),
           (uint8_t)(mac >> 24), (uint8_t)(mac >> 32), (uint8_t)(mac >> 40));
  identificador = String(macTxt);
  Serial.println();
  Serial.println("=== Nivel Certo ===");
  Serial.print("Identificador (MAC) deste dispositivo: ");
  Serial.println(identificador);

  prefs.begin("nc", false);
  wifiSsid = prefs.getString("ssid", "");
  wifiSenha = prefs.getString("pass", "");
  if (wifiSsid.length() == 0) {
    Serial.println("Nenhum Wi-Fi salvo.");
    modoConfiguracao();  // não volta daqui: reinicia quando o app configurar
  }
  Serial.print("Conectando ao WiFi salvo");
  if (!tentaWiFi(wifiSsid, wifiSenha, 20000)) {
    Serial.println(" falhou");
    modoConfiguracao();
  }
  Serial.println(" ok");

  ultimoEnvio = millis();
  ultimoSucesso = ultimoEnvio;
  xTaskCreate(tarefaVigia, "vigia", 2048, NULL, 1, NULL);
}

void loop() {
  verificaBotaoReset();

  // Teste dos sensores a cada 2 s enquanto espera o próximo envio
  static unsigned long ultimoTeste = 0;
  if (millis() - ultimoTeste >= 2000) {
    ultimoTeste = millis();
    unsigned long p;
    portENTER_CRITICAL(&mux); p = pulsos; portEXIT_CRITICAL(&mux);
    float d = medirRapido();
    Serial.printf("[teste] distancia: %.1f cm | pulsos acumulados: %lu\n", d, p);
  }

  if (millis() - ultimoEnvio >= INTERVALO_ENVIO_MS) {
    unsigned long agora = millis();
    float segundos = (agora - ultimoSucesso) / 1000.0f;
    conectaWiFi();

    float dist = medirDistanciaCm();
    unsigned long p;
    portENTER_CRITICAL(&mux); p = pulsos; portEXIT_CRITICAL(&mux);
    float litros = (p - pulsosNoUltimoEnvio) / PULSOS_POR_LITRO;
    float vazao = litros / (segundos / 60.0f);

    Serial.printf("Enviando: dist=%.1f cm, entrada=%.3f L, vazao=%.2f L/min\n", dist, litros, vazao);
    bool ok = (WiFi.status() == WL_CONNECTED) &&
              enviar(dist, !primeiroEnvio, litros, vazao);
    if (ok) {
      ultimoSucesso = agora;
      pulsosNoUltimoEnvio = p;   // só "zera" se o envio deu certo
      primeiroEnvio = false;
    }
    // Se falhou, os pulsos continuam acumulando e entram no próximo envio.
    ultimoEnvio = agora;
  }
}
