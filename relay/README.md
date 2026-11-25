# AETHER external cosmetics relay (v1)
A dependency-free Node.js 22+ backend for consent-based cosmetic exchange. Deploy this directory as the service root. Start command: npm start. Health endpoint: GET /health. Configure RELAY_ADMIN_SECRET with a newly generated strong random secret on the host; keep it server-side. Use HTTPS through the host. Run npm test for the protocol test.

## API
All POST routes accept JSON and Authorization: Bearer TOKEN. Never distribute the deployment secret or room-admin token in a Roblox client.
- POST /v1/rooms (deployment secret): creates an isolated room, returns room and adminToken.
- POST /v1/peers (room adminToken): provisions a participant, returns random slot and peerToken. A trusted application issues these only after explicit opt-in.
- POST /v1/sync (peerToken): body {cosmetics: {halo:true, ...}, since: optionalRevision}. Omitting cosmetics polls/heartbeats; responses include revision and a peer snapshot only when changed.
- POST /v1/leave (peerToken): revokes the participant.
- POST /v1/close (adminToken): deletes the room.
Slots are randomly generated, not Roblox account IDs. The authorized host/companion is responsible for mapping consenting participants to visible avatars locally and assigning separate rooms per game session. No public room directory or lookup by player. No chat, inventory, scripts, credentials or account identifiers belong in cosmetics.

## Limits and privacy
32 participants per room, 256 rooms per process, 8 KiB request body, 750 ms sync interval, 30 s inactive-participant expiry, 15 min idle room expiry and 6 h absolute room expiry. No persistent storage or application IP logging. The hosting provider may retain its own connection logs. Single process only; do not scale to multiple replicas without shared ephemeral storage. Restart clears all sessions.

## Current integration status
This backend is not yet deployed. The existing Roblox client continues to use the authorized in-place RemoteEvent relay. Ordinary Roblox LocalScripts cannot make arbitrary external HTTP requests. The new HTTP service is a transport for an authorized server or independently consented companion integration; it is not a standalone public-game client fix. No injector APIs, public-game workarounds, auto-discovery or account tracking are included. A trusted transport and local avatar mapping still need integration and testing. The server does not download or execute code from clients.
