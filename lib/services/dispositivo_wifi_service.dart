import 'dart:async';
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class ConfigWifiException implements Exception {
  final String mensagem;

  const ConfigWifiException(this.mensagem);

  @override
  String toString() => mensagem;
}

// Envia o Wi-Fi da casa para o dispositivo por Bluetooth.
// O dispositivo (ESP32) anuncia como "NC-<código>" quando ainda não tem Wi-Fi.
class DispositivoWifiService {
  DispositivoWifiService._();
  static final DispositivoWifiService instance = DispositivoWifiService._();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Iguais aos definidos no código da ESP32
  static final Uuid _servico = Uuid.parse('7f1a0001-5c1e-4b7a-9d3a-2c4e1f0a6b10');
  static final Uuid _config = Uuid.parse('7f1a0002-5c1e-4b7a-9d3a-2c4e1f0a6b10');
  static final Uuid _status = Uuid.parse('7f1a0003-5c1e-4b7a-9d3a-2c4e1f0a6b10');

  Future<void> configurarWifi({
    required String codigo,
    required String chave,
    required String ssid,
    required String senha,
  }) async {
    await _prepararBluetooth();
    final id = await _procurar('NC-$codigo');

    StreamSubscription<ConnectionStateUpdate>? conexao;
    try {
      final conectou = Completer<void>();
      conexao = _ble
          .connectToDevice(
            id: id,
            connectionTimeout: const Duration(seconds: 15),
          )
          .listen(
        (atualizacao) {
          if (atualizacao.connectionState == DeviceConnectionState.connected &&
              !conectou.isCompleted) {
            conectou.complete();
          }
        },
        onError: (Object _) {
          if (!conectou.isCompleted) {
            conectou.completeError(const ConfigWifiException(
              'Não foi possível conectar ao dispositivo por Bluetooth.',
            ));
          }
        },
      );
      await conectou.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw const ConfigWifiException(
          'Não foi possível conectar ao dispositivo por Bluetooth.',
        ),
      );

      try {
        await _ble.requestMtu(deviceId: id, mtu: 247);
      } catch (_) {
        // Segue com o tamanho padrão; se não couber, o envio falha abaixo
      }

      final caracteristicaConfig = QualifiedCharacteristic(
        serviceId: _servico,
        characteristicId: _config,
        deviceId: id,
      );
      final caracteristicaStatus = QualifiedCharacteristic(
        serviceId: _servico,
        characteristicId: _status,
        deviceId: id,
      );

      try {
        await _ble.writeCharacteristicWithResponse(
          caracteristicaConfig,
          value: utf8.encode('$ssid\n$senha\n$chave'),
        );
      } catch (_) {
        throw const ConfigWifiException(
          'Não foi possível enviar os dados ao dispositivo. Tente de novo.',
        );
      }

      // Acompanha o resultado: o dispositivo testa o Wi-Fi e responde
      var viuConectando = false;
      final limite = DateTime.now().add(const Duration(seconds: 40));
      while (DateTime.now().isBefore(limite)) {
        await Future.delayed(const Duration(seconds: 1));
        String estado;
        try {
          final bytes = await _ble.readCharacteristic(caracteristicaStatus);
          estado = utf8.decode(bytes, allowMalformed: true);
        } catch (_) {
          // O dispositivo reinicia depois de salvar o Wi-Fi e a conexão cai
          if (viuConectando) return;
          throw const ConfigWifiException(
            'A conexão com o dispositivo foi perdida. Tente de novo.',
          );
        }
        switch (estado) {
          case 'ok':
            return;
          case 'conectando':
            viuConectando = true;
            break;
          case 'erro_wifi':
            throw const ConfigWifiException(
              'O dispositivo não conseguiu entrar nessa rede. Confira o nome e '
              'a senha e se a rede é de 2,4 GHz.',
            );
          case 'chave_invalida':
            throw const ConfigWifiException('Chave do dispositivo incorreta.');
          case 'formato_invalido':
            throw const ConfigWifiException(
              'Nome ou senha do Wi-Fi inválidos (a senha deve ter de 8 a 63 '
              'caracteres).',
            );
        }
      }
      throw const ConfigWifiException(
        'O dispositivo não respondeu a tempo. Tente de novo.',
      );
    } finally {
      await conexao?.cancel();
    }
  }

  Future<void> _prepararBluetooth() async {
    // Pede as permissões de Bluetooth (e localização, exigida em Androids antigos)
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    BleStatus status;
    try {
      status = await _ble.statusStream
          .firstWhere((s) => s != BleStatus.unknown)
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      status = BleStatus.unknown;
    }

    switch (status) {
      case BleStatus.poweredOff:
        throw const ConfigWifiException(
          'Ligue o Bluetooth do celular e tente novamente.',
        );
      case BleStatus.unauthorized:
        throw const ConfigWifiException(
          'Permita o acesso ao Bluetooth para o aplicativo nas configurações do celular.',
        );
      case BleStatus.locationServicesDisabled:
        throw const ConfigWifiException(
          'Ative a localização do celular para procurar o dispositivo.',
        );
      case BleStatus.unsupported:
        throw const ConfigWifiException('Este celular não tem Bluetooth.');
      default:
        break;
    }
  }

  Future<String> _procurar(String nome) async {
    final encontrado = Completer<String>();
    final busca = _ble
        .scanForDevices(
          withServices: [_servico],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
      (dispositivo) {
        if (dispositivo.name == nome && !encontrado.isCompleted) {
          encontrado.complete(dispositivo.id);
        }
      },
      onError: (Object _) {
        if (!encontrado.isCompleted) {
          encontrado.completeError(const ConfigWifiException(
            'Não foi possível procurar o dispositivo. Confira as permissões '
            'de Bluetooth do aplicativo.',
          ));
        }
      },
    );
    try {
      return await encontrado.future.timeout(
        const Duration(seconds: 25),
        onTimeout: () => throw const ConfigWifiException(
          'Dispositivo não encontrado. Confira se está ligado na tomada, '
          'perto do celular, e se o código está correto.',
        ),
      );
    } finally {
      await busca.cancel();
    }
  }
}
