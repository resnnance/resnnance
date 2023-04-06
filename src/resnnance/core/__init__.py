import jinja2
import logging
import networkx as nx

class ReSNNance(object):

    def __init__(self):
        # Create templating environment
        self.env = jinja2.Environment(loader=jinja2.PackageLoader("resnnance.core"))

        # Create log
        self.logger = logging.getLogger("resnnance.core")
        self.logger.setLevel(logging.INFO)

        # Create log handler (for console output)
        handler = logging.StreamHandler()
        handler.setLevel(logging.INFO)

        # Format log output
        formatter = logging.Formatter( '%(asctime)s - %(name)s - %(levelname)s: %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

        # Log ReSNNance core creation
        self.logger.info("Created new ReSNNance core")

        # Network data
        self.network = nx.DiGraph()

    def create_snap(self, num):
        # Create template from string
        template = self.env.get_template("template.vhd")

        # Render template
        for i in range(num):
            # Set template parameters and render content
            params = {'entity_name': f"snap_{i}", 'arch_name': 'arch'}
            content = template.render(**params)

            # Write to files
            filename = f"snap_{i}.vhd"
            with open(filename, mode="w", encoding="utf-8") as message:
                message.write(content)
                self.logger.info(f"Wrote {filename}")

    def draw_network(self):
        pos = nx.spring_layout(self.network)

        # Draw
        node_sizes = [ndata['population'].size * 30 for node, ndata in self.network.nodes(data=True)]
        nx.draw(self.network, pos, with_labels=True, node_size=node_sizes)

        # Get connector name
        edge_labels = dict([((u, v), d['projection']._connector.__class__.__name__) for u, v, d in self.network.edges(data=True)])
        # Draw edge labels
        nx.draw_networkx_edge_labels(self.network, pos, edge_labels=edge_labels)
