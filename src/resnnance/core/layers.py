class Layer(object):

    def __init__(self, weights=None):
        raise NotImplementedError

    def set_layer(self, info):
        raise NotImplementedError

class Dense(Layer):

    def __init__(self, info=None):
        if info == None:
            self.weights = None
        else:
            self.set_layer(info['weights'])
    
    def set_layer(self, info):
        if info['weights'].shape == (2,2):
            self.weights = info['weights']  # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

class Conv2D(Layer):

    def __init__(self, info=None):
        if info == None:
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

        if info['kernel'].shape[2] == 1:    # z dim = 1 => Only 2D kernels
            self.kernel = info['kernel']    # Array of kernel weight matrices
        else:
            raise ValueError('Wrong kernel matrix')

class Pooling(Layer):

    def __init__(self, info=None):
        if info == None:
            self.n = None
            self.stride = None
            self.pool = None
        else:
            self.set_layer(info)

    def set_layer(self, info):
        self.n = info['n']              # Input dimensions (y,x,z)
        self.stride = info['stride']    # Stride steps (y,x)
        self.pool = info['pool']        # Pool size (y,x)