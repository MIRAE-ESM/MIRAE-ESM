# MIRAE-ESM

**Multiscale Integrated Research for Advanced Environment - Earth System Model**

**MIRAE-ESM** is a coupled climate modeling system that integrates the **GRIMs** atmospheric model with the **NEMO** ocean model.  
This top-level repository organizes the full modeling system using Git submodules.

---

## Repository Structure

The core components of MIRAE-ESM are managed as submodules.  
Below is the directory structure and its description:

| Component | Path | Description |
| :--- | :--- | :--- |
| **GRIMs-libs** | `./GRIMs/libs` | Libraries for the GRIMs atmospheric model |
| **GRIMs-srcs** | `./GRIMs/srcs` | Source code for the GRIMs atmospheric model |
| **GRIMs-chem** | `./GRIMs/srcs/src/chem` | Chemistry module for the GRIMs atmospheric model (nested within GRIMs-srcs) |
| **GRIMs-runs** | `./GRIMs/runs` | Run scripts for the GRIMs atmospheric model |
| **NEMO** | `./NEMO` | NEMO ocean model configured for MIRAE-ESM (coupled with GRIMs) |
| **LIBS** | `./LIBS` | External libraries (OASIS3-MCT, XIOS2) modified for MIRAE-ESM |
| **RUNDIRS** | `./RUNDIRS` | Main workspace for MIRAE-ESM simulations (includes run templates) |

> [!IMPORTANT]
> **GRIMs-runs** is for atmospheric model-only experiments.  
> For **coupled MIRAE-ESM simulations**, please use the `RUNDIRS` directory in the top-level repository.

---

## Getting Started

### 1. Clone the repository

To clone the repository along with all submodules (including nested ones), use:

```bash
git clone --recurse-submodules https://github.com/MIRAE-ESM/MIRAE-ESM.git
```

### 2. Update submodules

If you have already cloned the repository without submodules, run:

```bash
git submodule update --init --recursive
```

### 3. Download input data

The model requires specific input data for both atmospheric (CHEM) and ocean (NEMO) components.  
You can download them directly using the commands below:

**Chemistry Data:**

```bash
wget http://airchem.snu.ac.kr/private/CHEM_DATA.tar.gz
```

**NEMO Data:**

```bash
wget http://airchem.snu.ac.kr/private/NEMO_DATA.tar.gz
```

> [!TIP]
> After downloading, extract the files into your designated data path as specified in your `RUNDIRS` configuration.

---

## External Libraries (LIBS)

The `LIBS/` directory contains external coupling tools modified to support the MIRAE-ESM coupling interface:

* **OASIS3-MCT**: Coupler for atmosphere-ocean interaction.
* **XIOS2**: XML Input/Output Server for efficient data handling.

---

## Contact

For questions, bug reports, or collaboration inquiries, please contact:

**Seungun Lee, Ph.D.**  
*Seoul National University*  
[hb3099@hotmail.com](mailto:hb3099@hotmail.com) / [hb3099@snu.ac.kr](mailto:hb3099@snu.ac.kr)

---
