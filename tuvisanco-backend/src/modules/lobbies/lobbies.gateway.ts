import { WebSocketGateway, WebSocketServer, SubscribeMessage, MessageBody, ConnectedSocket } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({ cors: true, namespace: 'lobbies' })
export class LobbiesGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('joinLobby')
  handleJoinLobby(
    @MessageBody() data: { lobbyCode: string },
    @ConnectedSocket() client: Socket
  ) {
    client.join(data.lobbyCode);
    console.log(`User ${client.id} joined lobby room: ${data.lobbyCode}`);
    
    // Phát sự kiện thông báo cho mọi người trong phòng
    this.server.to(data.lobbyCode).emit('userJoined', { 
      socketId: client.id,
      message: `Người dùng ${client.id} đã vào phòng`
    });
  }

  @SubscribeMessage('leaveLobby')
  handleLeaveLobby(
    @MessageBody() data: { lobbyCode: string },
    @ConnectedSocket() client: Socket
  ) {
    client.leave(data.lobbyCode);
    console.log(`User ${client.id} left lobby room: ${data.lobbyCode}`);
  }

  // Hàm phát sóng bảng xếp hạng điểm cập nhật thời gian thực cho mọi người trong phòng
  broadcastLobbyScoreUpdate(lobbyCode: string, leaderboard: any) {
    this.server.to(lobbyCode).emit('scoreUpdated', leaderboard);
  }
}
