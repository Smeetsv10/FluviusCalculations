import numpy as np

def f_normalize(series):
    return (series - np.min(series)) / (np.max(series) - np.min(series))