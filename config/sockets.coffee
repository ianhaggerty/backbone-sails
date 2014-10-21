###
WebSocket Server Settings
(sails.config.sockets)

These settings provide transparent access to the options for Sails'
encapsulated WebSocket server, as well as some additional Sails-specific
configuration layered on top.

For more information on sockets configuration, including advanced config options, see:
http://sailsjs.org/#/documentation/reference/sails.config/sails.config.sockets.html
###
module.exports.sockets =
	transports: [
		'websocket',
		'htmlfile',
		'xhr-polling',
		'jsonp-polling',
		'flashsocket'
	]

	adapter: 'memory'

	onConnect: (session, socket) ->
	onDisconnect: (session, socket) ->

	'backwardsCompatibilityFor0.9SocketClients': true
	grant3rdPartyCookie: true
	origins: '*:*'
	heartbeats: true

	'close timeout': 60
	'heartbeat timeout': 60
	'heartbeat interval': 25
	'polling duration': 20
	'flash policy port': 10843
	'destroy buffer size': '10E7'
	'destroy upgrade': true
	'browser client': true
	'browser client cache': true
	'browser client minification': false
	'browser client etag': false
	'browser client expires': 315360000
	'browser client gzip': true
	resource: '/socket.io'