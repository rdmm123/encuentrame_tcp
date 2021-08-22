import 'dart:async';

import 'package:socket_io/socket_io.dart';

void main() {
  final server = Server();
  
  server.on('connection', (client){
    print('Connect to ${client.id}');

    client.on('stream', (data){
      print('Data from client:\n$data');
    });

    client.on('disconnect', (_) => print('Client $client disconnected.'));
    
  });

  server.listen(3000);
}
