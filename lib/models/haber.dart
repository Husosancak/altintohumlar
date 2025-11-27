class Haber {
  final int id;
  final String baslik;
  final String resim;
  final String tarih;
  final String saat;
  final bool online;
  final String? videoURL;
  final String? egitimPdf;
  final String aciklama;
  final String? basin;

  Haber({
    required this.id,
    required this.baslik,
    required this.resim,
    required this.tarih,
    required this.saat,
    required this.online,
    required this.videoURL,
    required this.egitimPdf,
    required this.aciklama,
    required this.basin,
  });

  factory Haber.fromJson(Map<String, dynamic> json) {
    return Haber(
      id: json['id'],
      baslik: json['baslik'],
      resim: json['resim'],
      tarih: json['tarih'],
      saat: json['saat'],
      online: json['online'],
      videoURL: json['videoURL'],
      egitimPdf: json['egitimPdf'],
      aciklama: json['aciklama'],
      basin: json['basin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baslik': baslik,
      'resim': resim,
      'tarih': tarih,
      'saat': saat,
      'online': online,
      'videoURL': videoURL,
      'egitimPdf': egitimPdf,
      'aciklama': aciklama,
      'basin': basin,
    };
  }
}
