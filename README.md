# MusPerSDT

Adaptive **two-alternative forced-choice (2AFC)** signal detection testing for
music signals. `MusPerSDT` estimates the **detection threshold for the soft part
of a music sample that immediately follows a loud part**, in within-subject
studies with hearing-impaired listeners.

## Installation

```r
# install.packages("remotes")
remotes::install_github("CLesimple/MusPer_SignalDetectionTest")
```

The package depends on [`tuneR`](https://cran.r-project.org/package=tuneR) for
reading and writing WAV files.

## Quick start (simulated observer)

You can exercise the full pipeline without any human input or real audio by
using the built-in simulated observer:

```r
library(MusPerSDT)

# Run an adaptive 2AFC test for one subject/condition using a simulated
# observer. Results are written to CSV in output_dir.
res <- run_test(
  subject_id = "S01",
  condition  = "progA",
  engine     = "levitt",
  observer   = simulate_observer(true_threshold = -12, slope = 0.5),
  output_dir = tempdir()
)

res$summary   # one row per sample with the estimated threshold
res$files     # paths to the history and summary CSV files
```

With real stimuli, drop your WAV files into `inst/extdata/` (see the layout in
`inst/extdata/README.md`) and omit `observer` to collect real responses.

## Design decisions

This section records the key design decisions and the rationale behind them.

### Experiment goal

The test measures the **detection threshold for the softer part of a music
excerpt that follows a loud part**. This mirrors a realistic listening
situation in which a quiet passage can be masked or missed after a loud one, and
is particularly relevant for hearing-impaired listeners.

### Why adaptive 2AFC

- **2AFC** (two intervals, one with the signal, one silent) gives a criterion-free
  measure of detectability with a known guess rate (50%).
- An **adaptive** procedure concentrates trials near each listener's own
  threshold, so the test **matches individual audibility** instead of using a
  fixed, one-size-fits-all level. This is efficient and fair across listeners
  with very different hearing.

### Two conditions and multiple samples

- The design supports **two conditions** (for example, two hearing-aid settings)
  so differences between settings can be compared **within subject**.
- Several **music samples** are used so that the result is not tied to one
  excerpt; averaging across samples accounts for **stimulus variability**.
- Overall design: `listener x condition x sample`.

### 2AFC trial structure

Each trial presents **two intervals**:

- one interval contains **silence**,
- the other contains the **soft test signal** (`<sample>_soft.wav`).

The listener indicates which interval contained the signal. The adaptive
variable is a **broadband gain in dB applied to the soft part**; the threshold
is reported in dB.

### Levitt staircase parameters

- **Levitt (1971) transformed up-down**, **2-down/1-up** (targets ~70.7%
  correct).
- **Step sizes:** **4 dB for the first 2 reversals**, then **2 dB for the next 4
  reversals** (6 reversals by default). These are configurable.
- **Threshold** is the mean of the reversal levels collected at the smaller
  (2 dB) step size.

A **QUEST+/Psi** Bayesian engine is available behind the same interface as an
alternative to the staircase.

### Calibration

Calibration is a **one-time system calibration**:

1. Play the calibration file `inst/extdata/calibration/calibration_65dBA.wav`.
2. Watch an **external SPL meter** and adjust the playback gain until it reads
   **65 dB(A)**.
3. Keep the playback settings fixed and run the test with those same settings.

In software, `calibrate_from_file()` anchors the calibration file's **digital
RMS level** to **65 dB(A) SPL** using a single broadband reference (the standard
`20*log10(RMS)` relationship). No A-weighting filter is applied in software; the
dB(A) reference is supplied by the external meter.

### Folder structure convention

Audio lives under `inst/extdata/` so it installs with the package and is found
at runtime via `system.file()`:

```
inst/extdata/
|-- calibration/
|   `-- calibration_65dBA.wav        # mono 44.1 kHz 16-bit, 65 dB(A) SPL reference
`-- samples/
    |-- sampleA/
    |   |-- sampleA_loud.wav
    |   `-- sampleA_soft.wav
    |-- sampleB/
    |   |-- sampleB_loud.wav
    |   `-- sampleB_soft.wav
    `-- ...                           # one folder per sample
```

Each sample is **one folder**; the sample ID is the folder name, and the folder
must contain `<id>_loud.wav` and `<id>_soft.wav`.

### Output files

Each run writes **two CSV files** with unique, explicit names:

- `<subjectID>_<condition>_<timestamp>_history.csv` — the **full trial history
  for all samples in a single file** (one row per trial).
- `<subjectID>_<condition>_<timestamp>_summary.csv` — one row per sample with the
  final threshold.

The timestamp uses `YYYYMMDD_HHMMSS` so filenames are unique and sortable.

## License

MIT (see `LICENSE`).
