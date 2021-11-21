cls
# Generate nodes
$nodes = @{}
$nodes['nodes'] = @()

# Value below affects size of node
# Group below affect color of node

$var = @{id = 1; label = "Kevin"; title = "Kevin Roman"; value = 21; group = 24
    # Can also add components in here for position on the map once it's generated
    #x = "717.32806",
    #y = "699.96234",
}
$nodes['nodes'] += $var
$var = @{id = 2; label = "Lauren"; title = "Lauren Salopek"; value = 21; group = 11}
$nodes['nodes'] += $var
$var = @{id = 3; label = "Roro"; title = "Rory Roman"; value = 22; group = 6}
$nodes['nodes'] += $var

$javascript_nodes = $nodes | ConvertTo-Json
$javascript_nodes = $($javascript_nodes[1..$($javascript_nodes.length - 2)] -join "").trim() -replace '"nodes":','var nodes ='


# Generate edges
$edges = @{}
$edges['edges'] = @()

# Value scales thckness of the line
# title is the "hover over" value
# label is the permanent view value

$var = @{from = 1; label = "Hello\nWorld!"; to = 2; value = 5}
$edges['edges'] += $var
$var = @{from = 1; to = 2; value = 2; title = "partner"; color = "black"}
$edges['edges'] += $var
$var = @{from = 1; to = 3}
$edges['edges'] += $var
$var = @{from = 2; to = 3}
$edges['edges'] += $var

$javascript_edges = $edges | ConvertTo-Json
$javascript_edges = $($javascript_edges[1..$($javascript_edges.length - 2)] -join "").trim() -replace '"edges":','var edges ='

$javascript_nodes
$javascript_edges

remove-item "C:\users\kroman\Desktop\datasources\test_source.js" -Force
Add-Content -Path "C:\users\kroman\Desktop\datasources\test_source.js" -Value $javascript_nodes
Add-Content -Path "C:\users\kroman\Desktop\datasources\test_source.js" -Value ""
Add-Content -Path "C:\users\kroman\Desktop\datasources\test_source.js" -Value $javascript_edges
Get-Content "C:\users\kroman\Desktop\datasources\test_source.js"

$main_file = @'
<html>
<head>
    <script type="text/javascript" src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
	<script src="./datasources/test_source.js"></script>
	<!--<script src="file://users/kroman/desktop/datasources/test_source.js"></script>-->

    <style type="text/css">
        #mynetwork {
            width: 600px;
            height: 400px;
            border: 1px solid lightgray;
        }
    </style>
</head>
<body>
<div id="mynetwork"></div>

<script type="text/javascript">
	// create an array with nodes
	var nodesDataset = new vis.DataSet(nodes);
	// create an array with nodes
	var edgesDataset = new vis.DataSet(edges);
    // create a network
    var container = document.getElementById('mynetwork');
	
        var options = {
          nodes: {
            shape: "dot",
            scaling: {
              min: 10,
              max: 30,
              label: {
                min: 8,
                max: 30,
                drawThreshold: 12,
                maxVisible: 20,
              },
            },
            font: {
              size: 12,
              face: "Tahoma",
            },
          },
          edges: {
            width: 0.15,
            color: { inherit: "from" },
            smooth: {
              type: "continuous",
            },
          },
          physics: false,
          interaction: {
            tooltipDelay: 200,
            hideEdgesOnDrag: true,
            hideEdgesOnZoom: true,
          },
        };

    // provide the data in the vis format
	var data = { nodes: nodesDataset, edges: edgesDataset };

    // initialize your network!
    var network = new vis.Network(container, data, options);
</script>
</body>
</html>
'@

remove-item "C:\users\kroman\Desktop\test.html" -Force
Add-Content -Path "C:\users\kroman\Desktop\test.html" -Value $main_file