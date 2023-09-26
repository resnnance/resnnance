DEFAULT = 1

class Layer(object):

    def __init__(self, label, info=None):
        raise NotImplementedError

    def set_layer(self, info):
        raise NotImplementedError

    def get_size(self):
        raise NotImplementedError

class Input(Layer):

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

class Dense(Layer):

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

class Conv2D(Layer):

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

class Pooling(Layer):

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