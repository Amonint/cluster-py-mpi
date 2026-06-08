from mpi4py import MPI
import numpy as np

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

N = 1_000_000
local_n = N // size
start = rank * local_n
end = start + local_n if rank < size - 1 else N

local_sum = float(np.sum(np.arange(start, end, dtype=np.float64)))
total = comm.reduce(local_sum, op=MPI.SUM, root=0)

if rank == 0:
    expected = N * (N - 1) / 2
    print(f"Suma local acumulada por {size} procesos: {total:.0f}")
    print(f"Resultado esperado: {expected:.0f}")
    print(f"Correcto: {abs(total - expected) < 1e-3}")
