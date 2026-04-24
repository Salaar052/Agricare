class MessageModel {
  final String sender;
  final String? message;
  final String? fileUrl;

  MessageModel({
    required this.sender,
    this.message,
    this.fileUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      sender: json["sender"],
      message: json["message"],
      fileUrl: json["fileUrl"],
    );
  }
}
  