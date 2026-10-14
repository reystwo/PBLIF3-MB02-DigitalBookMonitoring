class UserModel {
  final int idUser;
  final String nama;
  final String username;
  final String role;
  final String status;
  final String peranLabel;
  final Map<String, dynamic>? guru;
  final Map<String, dynamic>? orangTua;

  const UserModel({
    required this.idUser,
    required this.nama,
    required this.username,
    required this.role,
    required this.status,
    required this.peranLabel,
    this.guru,
    this.orangTua,
  });

  String? get namaGuru => guru?['nama_guru']?.toString();
  String? get namaOrangTua => orangTua?['nama_orang_tua']?.toString();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idUser: json['id_user'] is int
          ? json['id_user']
          : int.tryParse(json['id_user']?.toString() ?? '0') ?? 0,
      nama: json['nama']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? 'aktif',
      peranLabel: json['peran_label']?.toString() ?? ucfirst(json['role']?.toString() ?? ''),
      guru: json['guru'] is Map<String, dynamic> ? json['guru'] : null,
      orangTua: json['orang_tua'] is Map<String, dynamic> ? json['orang_tua'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': idUser,
      'nama': nama,
      'username': username,
      'role': role,
      'status': status,
      'peran_label': peranLabel,
      'guru': guru,
      'orang_tua': orangTua,
    };
  }

  static String ucfirst(String str) {
    if (str.isEmpty) return '';
    return str[0].toUpperCase() + str.substring(1);
  }
}
