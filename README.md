# LocalMicroFirewallAvoidanceOutput

L.M.F.A.O. will allow you to turn on firewall logging on your endpoints and log all allowed connections for X amount of time. After X time elapses, analytics will be done to list all communications between host computer and all other systems.

This data will be fed into neo4j and L.M.F.A.O. will produce a map to visually display how your systems talk. All this data will be aggregated, and produce a "searchable" interface to allow search term "Server A" and it returns a map showing all systems that "Server A" talks to and all servers that talk back to "Server A".

Items included in report: Port, Protocol, Traffic Direction, and Frequency of conversations over time\duration of data collection)

Phase 1: An easy to consume list of suggested firewall rules for each individual node will be generated if you want to limit traffic on a specific port for a specific host.

Phase 2: Show clear conversation paths (including beginning\ending nodes).
