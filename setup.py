from Cython.Build import cythonize
from distutils.core import setup

setup(
    name='lshpack',
    version='0.1.0dev0',
    description='Bindings to the ls-hpack library',
    author='Vladimir Magamedov',
    author_email='vladimir@magamedov.com',
    license='BSD-3-Clause',
    ext_modules=cythonize('lshpack.pyx'),
)
