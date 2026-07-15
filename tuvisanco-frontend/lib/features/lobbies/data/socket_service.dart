import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/network/dio_client.dart';

class SocketService {
  late IO.Socket socket;

  void connect(String roomCode) {
    // Kết nối tới WebSockets Namespace 'lobbies' trên Backend
    socket = IO.io('$baseUrl/lobbies', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Đã kết nối tới WebSockets Server thành công');
      // Gửi sự kiện Join vào phòng
      socket.emit('joinLobby', {'lobbyCode': roomCode});
    });

    socket.on('userJoined', (data) {
      print('Phát hiện thành viên mới vào phòng: $data');
    });

    socket.on('scoreUpdated', (data) {
      print('Bảng xếp hạng điểm realtime được cập nhật: $data');
    });

    socket.onDisconnect((_) {
      print('Mất kết nối tới WebSockets Server');
    });
  }

  void disconnect(String roomCode) {
    socket.emit('leaveLobby', {'lobbyCode': roomCode});
    socket.disconnect();
  }
}
