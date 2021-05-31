#!/bin/bash
#SBATCH --job-name=s=0.472_g=50_self_assembly
#SBATCH --account=nn4654k
#SBATCH --time=1-0:0:0
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=128

set -o errexit
module load h5py/2.10.0-foss-2020a-Python-3.8.2
module load pfft-python/0.1.21-foss-2020a-Python-3.8.2
set -x

export MPI_NUM_RANKS=32
export OMP_NUM_THREADS=1

# Copy data to /cluster/work/users/mortele/$SLURM_JOB_ID
export SCRATCH="/cluster/work/users/mortele/${SLURM_JOB_ID}"
mkdir ${SCRATCH}
OUT_DIR=${SLURM_SUBMIT_DIR}/hymd-ec-out

DEST_1=${SCRATCH}/dest_1; mkdir ${DEST_1}
DEST_2=${SCRATCH}/dest_2; mkdir ${DEST_2}
DEST_3=${SCRATCH}/dest_3; mkdir ${DEST_3}
DEST_4=${SCRATCH}/dest_4; mkdir ${DEST_4}
DEST=( ${DEST_1} ${DEST_2} ${DEST_3} ${DEST_4} )

mkdir -p ${OUT_DIR}
cd ${SCRATCH}
mkdir ${SCRATCH}/hymd/
mkdir ${SCRATCH}/utils/
cp ${HOME}/HyMD-2021/hymd/* hymd/
cp ${HOME}/HyMD-2021/utils/* utils/
cp ${SLURM_SUBMIT_DIR}/dppc_random.h5 ${SCRATCH}/inp.h5

# Find any files named config*.toml, fall back to any file named *.toml if none
# are found
CONFIG_FILE=$(/bin/ls ${SLURM_SUBMIT_DIR} | grep "config.*.toml")
if [ -z "${CONFIG_FILE}" ]; then
  CONFIG_FILE=$(/bin/ls ${SLURM_SUBMIT_DIR} | grep ".toml")
  if [ -z "${CONFIG_FILE}" ]; then
    exit 404 # No config file found
  fi
fi
cp ${SLURM_SUBMIT_DIR}/${CONFIG_FILE} ${SCRATCH}/config.toml


date
srun --nodes 1 --ntasks ${MPI_NUM_RANKS} --exclusive                           \
     python3 hymd/main.py config.toml inp.h5                                   \
     --logfile=log_1.txt --verbose 2 --velocity-output --destdir ${DEST_1}     \
     
for i in {2..4}; do
  d=${DEST[$(expr $i - 1)]}

  sleep 2
  srun --nodes 1 --ntasks ${MPI_NUM_RANKS} --exclusive                         \
       python3 hymd/main.py config.toml inp.h5                                 \
       --logfile=log_${i}.txt --verbose 2 --velocity-output --destdir ${d}     \
       --seed ${i} --double-precision &> /dev/null &

done
wait

cp -r ${SCRATCH}/* ${OUT_DIR}/
