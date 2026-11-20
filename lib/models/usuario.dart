class Usuario {
  final String nome;
  final String dataNascimento;
  final String genero;
  final String contato; // e-mail ou celular
  String senha;

  Usuario({
    required this.nome,
    required this.dataNascimento,
    this.genero = '',
    required this.contato,
    required this.senha,
  });
}
