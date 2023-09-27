DEFAULT = 1

class Layer(object):
    template = None

    def __init__(self, label, info=None):
        raise NotImplementedError

    def set_layer(self, info):
        raise NotImplementedError

    def get_size(self):
        raise NotImplementedError

    def get_template_params(self):
        """
        Returns all needed parameters for the generation of a VHDL
        template
        """
        raise NotImplementedError

class Input(Layer):
    template = "hw/snaps/input.vhd"

    def __init__(self, label, info=None):
        self.label = label

        if info is None:
            self.weights = None
        else:
            self.set_layer(info)
    
    def set_layer(self, info):
        if info.ndim == 2:
            self.weights = info     # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return self.weights.shape[1]

    def get_template_params(self):
        return {'weights': self.weights}

class Dense(Layer):
    template = "hw/snaps/dense.vhd"

    def __init__(self, label, info=None):
        self.label = label

        if info is None:
            self.weights = None
        else:
            self.set_layer(info)
    
    def set_layer(self, info):
        if info.ndim == 2:
            self.weights = info     # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return len(self.weights.flatten())

    def get_template_params(self):
        return {'weights': self.weights}

class Conv2D(Layer):
    template = "hw/snaps/conv2d.vhd"

    def __init__(self, label, info=None):
        self.label = label

        if info is None:
            self.n = None
            self.stride = None
            self.padding = None
            self.kernel = None
        else:
            self.set_layer(info)

    def set_layer(self, info):
        self.n = info['n']              # Input dimensions (y,x,z)
        self.stride = info['stride']    # Stride steps (y,x)
        self.padding = info['padding']  # Padding (valid, none)
        self.kernel = info['kernel']    # Array of kernel weight matrices

    def get_size(self):
        if self.kernel is None:
            return DEFAULT
        else:
            return len(self.kernel.flatten())

    def get_template_params(self):
        return {
            'n': self.n,
            'stride': self.stride,
            'padding': self.padding,
            'kernel': self.kernel
        }

class Pooling(Layer):
    template = "hw/snaps/pooling.vhd"

    def __init__(self, label, info=None):
        self.label = label

        if info is None:
            self.n = None
            self.stride = None
            self.pool = None
        else:
            self.set_layer(info)

    def set_layer(self, info):
        self.n = info['n']              # Input dimensions (y,x,z)
        self.stride = info['stride']    # Stride steps (y,x)
        self.pool = info['pool']        # Pool size (y,x)

    def get_weight(self):
        return 1 / (self.pool[0] * self.pool[1])

    def get_size(self):
        if self.pool is None:
            return DEFAULT
        else:
            return self.pool[0] * self.pool[1] 

    def get_template_params(self):
        return {
            'n': self.n,
            'stride': self.stride,
            'pool': self.pool
        }