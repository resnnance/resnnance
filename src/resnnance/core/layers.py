import numpy as np

DEFAULT = 1

class Layer(object):
    templates = None

    def __init__(self, label, info=None):
        raise NotImplementedError

    def set_layer(self, info):
        raise NotImplementedError
    
    def get_size(self):
        raise NotImplementedError

    def get_logn(self):
        raise NotImplementedError

    def get_template_params(self):
        """
        Returns all needed parameters for the generation of a VHDL
        template
        """
        raise NotImplementedError

class Input(Layer):
    templates = {
        'core':    "hw/layers/input.vhd",
        'weights': "hw/layers/input_weights.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

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

    def get_logn(self):
        if self.weights is None:
            return DEFAULT
        else:
            return int(np.ceil(np.log2(self.weights.shape[1])))

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'weights': self.label + "_weights"
            },
            'weights': {
                'name': self.label + "_weights",
                'weights': self.weights
            }
        }
        return params

class Dense(Layer):
    templates = {
        'core':    "hw/layers/dense.vhd",
        'weights': "hw/layers/dense_weights.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

        if info is None:
            self.weights = None
        else:
            self.set_layer(info)
    
    def set_layer(self, info):
        if info.ndim == 2:
            self.weights = info     # Dense weight matrix
        else:
            raise ValueError('Wrong weight matrix shape')

    def get_logn(self):
        if self.weights is None:
            return DEFAULT
        else:
            return int(np.ceil(np.log2(self.weights.shape[1])))

    def get_size(self):
        if self.weights is None:
            return DEFAULT
        else:
            return len(self.weights.flatten())

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'weights': self.label + "_weights",
                'logm': int(np.ceil(np.log2(self.weights.shape[0]))),
                'logn': int(np.ceil(np.log2(self.weights.shape[1]))),
            },
            'weights': {
                'name': self.label + "_weights",
                'weights': self.weights,
                'm': self.weights.shape[0],
                'n': self.weights.shape[1]
            }
        }
        return params

class Conv2D(Layer):
    templates = {
        'core':   "hw/layers/conv2d.vhd",
        'kernel': "hw/layers/conv2d_kernel.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

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

    def get_logn(self):
        if self.kernel is None:
            return DEFAULT
        else:
            return 1

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'kernel': self.label + "_kernel",
                'n': self.n,
                'stride': self.stride,
                'padding': self.padding
            },
            'kernel': {
                'name': self.label + "_kernel",
                'kernel': self.kernel
            }
        }
        return params

class Pooling(Layer):
    templates = {
        'core': "hw/layers/pooling.vhd"
    }

    def __init__(self, label, info=None):
        self.label = "layer_" + label

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

    def get_logn(self):
        if self.pool is None:
            return DEFAULT
        else:
            return 1

    def get_template_params(self):
        params = {
            'core': {
                'name': self.label,
                'n': self.n,
                'stride': self.stride,
                'pool': self.pool
            }
        }
        return params