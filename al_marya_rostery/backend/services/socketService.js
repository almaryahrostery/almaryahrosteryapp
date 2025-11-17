const socketIO = require('socket.io');
const jwt = require('jsonwebtoken');

let io = null;

// Initialize Socket.IO
function initializeSocket(server) {
  io = socketIO(server, {
    cors: {
      origin: process.env.CLIENT_URL || '*',
      methods: ['GET', 'POST'],
      credentials: true
    },
    transports: ['websocket', 'polling']
  });

  // Middleware to authenticate socket connections
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        console.log('Socket connection attempt without token');
        // Allow connection but mark as unauthenticated
        socket.isAuthenticated = false;
        return next();
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.id;
      socket.userRoles = decoded.roles || [];
      socket.isAuthenticated = true;

      console.log(`Socket authenticated for user: ${socket.userId}`);
      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      socket.isAuthenticated = false;
      next(); // Allow connection but unauthenticated
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    console.log(`Socket connected: ${socket.id}, User: ${socket.userId || 'guest'}`);

    // Join order tracking room
    socket.on('join_order_room', async ({ orderId, roomName }) => {
      try {
        const room = roomName || `order_room_${orderId}`;

        // Authorization check: only allow user's own orders or staff/driver/admin
        // In production, verify user has access to this order
        if (!socket.isAuthenticated && !process.env.ALLOW_GUEST_TRACKING) {
          socket.emit('error', { message: 'Authentication required' });
          return;
        }

        socket.join(room);
        console.log(`Socket ${socket.id} joined room: ${room}`);

        socket.emit('joined_order_room', {
          orderId,
          roomName: room,
          message: 'Successfully joined tracking room'
        });

        // Send initial room info
        socket.to(room).emit('user_joined', {
          userId: socket.userId,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('Error joining order room:', error);
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    // Leave order tracking room
    socket.on('leave_order_room', ({ orderId, roomName }) => {
      const room = roomName || `order_room_${orderId}`;
      socket.leave(room);
      console.log(`Socket ${socket.id} left room: ${room}`);

      socket.to(room).emit('user_left', {
        userId: socket.userId,
        timestamp: new Date().toISOString()
      });
    });

    // Handle driver location updates (from driver app)
    socket.on('driver_location_update', ({ orderId, lat, lng, speed, heading }) => {
      const room = `order_room_${orderId}`;

      io.to(room).emit('driver_location', {
        orderId,
        lat,
        lng,
        speed,
        heading,
        timestamp: new Date().toISOString()
      });

      console.log(`Driver location update for order ${orderId}: ${lat}, ${lng}`);
    });

    // Handle status updates
    socket.on('status_update', ({ orderId, status, message }) => {
      const room = `order_room_${orderId}`;

      io.to(room).emit('order_status', {
        orderId,
        status,
        message,
        timestamp: new Date().toISOString()
      });

      console.log(`Status update for order ${orderId}: ${status}`);
    });

    // Handle ETA updates
    socket.on('eta_update', ({ orderId, etaStart, etaEnd, distanceMeters, durationSeconds }) => {
      const room = `order_room_${orderId}`;

      io.to(room).emit('eta_update', {
        orderId,
        etaStart,
        etaEnd,
        distanceMeters,
        durationSeconds
      });

      console.log(`ETA update for order ${orderId}`);
    });

    // Handle ping/pong for connection health
    socket.on('ping', () => {
      socket.emit('pong', { timestamp: new Date().toISOString() });
    });

    // Disconnection handler
    socket.on('disconnect', (reason) => {
      console.log(`Socket disconnected: ${socket.id}, Reason: ${reason}`);
    });

    // Error handler
    socket.on('error', (error) => {
      console.error(`Socket error from ${socket.id}:`, error);
    });
  });

  console.log('Socket.IO initialized successfully');
  return io;
}

// Get IO instance
function getIO() {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
}

// Emit to specific room
function emitToRoom(room, event, data) {
  if (io) {
    io.to(room).emit(event, data);
  }
}

// Emit to specific order
function emitToOrder(orderId, event, data) {
  const room = `order_room_${orderId}`;
  emitToRoom(room, event, { orderId, ...data });
}

module.exports = {
  initializeSocket,
  getIO,
  emitToRoom,
  emitToOrder
};
