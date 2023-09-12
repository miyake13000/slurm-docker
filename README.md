# slurm-docker
## Summary
The Docker container for building SLURM

## Preparation
1. [Install Docker](https://docs.docker.com/engine/install/).
2. Clone this repository to all nodes.
    ```bash
    $ git clone https://github.com/miyake13000/slurm-docker.git
    $ cd slurm-docker.git
    ```
3. Build docker container image and create 'munge.key' on each node.
    ```bash
    $ setup.sh
    ```
4. Share 'munge.key' for all nodes.
5. Create 'slurm.conf' and rewrite as neccesary.
    ```bash
    $ cp slurm.conf.sample slurm.conf
    $ vim slurm.conf
    ```

## Usage
* Run SLURM
    ```bash
    ./launch start
    [slurm@compute-node1]
       # You entered into slurm container
       # You can use srun, sbatch, and other slurm commands
    ```
* Stop SLURM
    ```bash
    [slurm@compute-node1] exit
    ```
