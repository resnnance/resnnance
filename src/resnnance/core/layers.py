DEFAULT = 1

class Layer(object):

    def __init__(self):
        raise NotImplementedError

    def set_layer(self, info):
        raise NotImplementedError

    def get_size(self):
        raise NotImplementedError

class Input(Layer):

    def __init__(self, label, info=None):
        self.label = label

        if info == None:
            self.weights = None
        else:
            self.set_layer(info['weights'])
    
    def set_layer(self, info):
        if info['weights'].shape == (2,2):
            self.weights = info['weights']  # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_size(self):
        if self.weights == None:
            return DEFAULT
        else:
            return len(self.weights.flatten())

class Dense(Layer):

    def __init__(self, label, info=None):
        self.label = label

        if info == None:
            self.weights = None
        else:
            self.set_layer(info['weights'])
    
    def set_layer(self, info):
        if info['weights'].shape == (2,2):
            self.weights = info['weights']  # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_size(self):
        if self.weights == None:
            return DEFAULT
        else:
            return len(self.weights.flatten())

class Conv2D(Layer):

    def __init__(self, label, info=None):
        self.label = label

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

    def get_size(self):
        if self.kernel == None:
            return DEFAULT
        else:
            return len(self.kernel.flatten())

class Pooling(Layer):

    def __init__(self, label, info=None):
        self.label = label

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

    def get_size(self):
        if self.pool == None:
            return DEFAULT
        else:
            return self.pool[0] * self.pool[1] 