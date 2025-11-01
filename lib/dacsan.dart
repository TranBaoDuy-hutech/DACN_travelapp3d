class DacSan {
  final int? id;
  final String tenMon;
  final String moTa;
  final String quaTrinhHinhThanh;
  final String modelUrl;

  DacSan({
    this.id,
    required this.tenMon,
    required this.moTa,
    required this.quaTrinhHinhThanh,
    required this.modelUrl,
  });

  factory DacSan.fromJson(Map<String, dynamic> json) {
    return DacSan(
      id: json['id'],
      tenMon: json['tenMon'],
      moTa: json['moTa'],
      quaTrinhHinhThanh: json['quaTrinhHinhThanh'],
      modelUrl: json['modelUrl'],
    );
  }
}
