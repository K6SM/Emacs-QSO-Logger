# Emacs-QSO-Logger

An Emacs form for logging amateur radio contacts (QSOs) to an ADIF file.

`qso.el` provides `qso-log-form`, a customizable form built from almost any
combination of ADIF fields, so it can be set up for contest work or for general
logging. Every setting is in the QSO customization group, under "Applications"
in `M-x customize`.

Logs can be processed further within Emacs or imported into another logging
program.

## Features

- Text interface for real-time logging, or for entering paper logs
- Runs in a Linux terminal, so it suits low-power hardware such as a
  Raspberry Pi Zero 2W in terminal-only mode
- No mouse required: `TAB` and `S-<tab>` move between fields and buttons
- Entries are appended to a user-specified ADIF file
- Any ADIF field can appear on the form, in any order
- Field names, the values each field accepts, and the format of the log come
  from [adif-mode](https://github.com/K6SM/adif-mode)
- A field with a short list of values is a menu; one with a longer list (MODE,
  SUBMODE, CONTEST_ID, DXCC, ARRL_SECT) is typed, and `M-TAB` completes it
- Before a contact is logged, each value is checked against the ADIF
  specification: dates, times, numbers and their ranges, locators, IOTA, POTA,
  SOTA and WWFF references, codes, and SUBMODE against MODE. Anything
  questionable is listed, with the choice to log it anyway
- Codes and fields ADIF allows only in old logs are not offered
- Each field can keep its value after a submission — useful when frequency and
  mode are unchanged between contacts, and for repeating sent reports in
  contests
- BAND is filled in from FREQ for the common bands when BAND is blank or absent
  from the form
- FREQ, MODE and SUBMODE follow the radio through Hamlib's `rigctld`
- Callsign lookup, either reported in a separate buffer or filled into the form
- Duplicate checking before a contact is recorded
- The form can be cleared without saving, for an incomplete contact

## Manual Installation

1. Place qso.el and adif.el 1.0.7 or later (from
   [adif-mode](https://github.com/K6SM/adif-mode)) in the load path. If one
   hasn't been established, you can place them in `~/.emacs.d/lisp/` and then,
   in the init.el file (located in `~/.emacs.d/`) add:
   `(add-to-list 'load-path "~/.emacs.d/lisp/")`
2. Add to the init.el file: `(require 'qso)`
3. Restart Emacs

## Getting Started

1. Execute `M-x customize`, select "Applications" and then "QSO".
2. Enter your callsign in the QSO Operator field.
3. Enter the path to the ADIF file you will be using (e.g. `~/qsolog.adi`).
4. Add, remove, or reorder the fields you wish to have on the form.
5. Select the fields to be cleared after a submission (helpful for contests).
6. Optionally, set the width of any field in QSO Field Widths, and the most
   values a field may have and still be a menu in QSO Menu Choice Limit
   (35 by default).
7. Click "Apply" or "Apply and Save" as appropriate.
8. Execute `M-x qso-log-form`.

The form looks like this:

    QSO Log Entry   K6SM   /home/dave/qsolog.adi
    IC-7300  localhost:4532  connected  14.074000 MHz  USB

      CALL         W1AW      [Lookup]
      NAME         Hiram
      RST_RCVD     599
      RST_SENT     599
      FREQ         14.074000  MHz
      MODE         SSB
      COMMENT

    [Submit] [Clear] [Quit]

The second line appears only when the radio is being read; see below.

## Keys

| Key | |
|-----|--|
| `TAB` `S-<tab>` | Next / previous field or button |
| `RET` | Press the button at point, or finish entering a field |
| `M-TAB` | Complete the value where the field offers a choice |
| `C-c C-l` | Look up the callsign; `C-u C-c C-l` also fills the fields |
| `C-c C-r` | Read frequency and mode from the radio now |
| `C-c C-t` | Start or stop following the radio |
| `C-c ?` | List these keys and the buttons |
| `C-h m` | Describe the mode in full |

The four `C-c` commands work inside a field as well as between fields. They
are also on the QSO menu.

Buttons: **Submit** writes the QSO, **Clear** empties the fields without
writing, **Quit** closes the form.

The date, time and operator are added when the contact is written.

## Looking Up Callsigns (optional)

`C-c C-l`, or the **Lookup** button, reports what is known about the callsign
in a separate buffer. `C-u C-c C-l` also fills in the fields named by "QSO Callsign
Lookup Fields". A field you have already typed into is never overwritten, and a
field that is not on the form is written to the ADIF record when the QSO is
submitted.

Turning on "QSO Callsign Lookup Autofill" adds a **Lookup & Autofill** button
beside **Lookup**. "QSO Callsign Lookup" controls the **Lookup** button itself;
`C-c C-l` works either way.

"QSO Callsign Lookup Source" selects where details come from:

| Source | |
|--------|--|
| `callook` | callook.info, United States only, no account (the default) |
| `hamqth` | HamQTH, worldwide, free account |
| `qrz` | QRZ.com, worldwide, paid XML subscription |
| `nil` | No online lookup |

HamQTH and QRZ.com need a login. Set "QSO Callsign Lookup User" to your
callsign and put the password in `~/.authinfo.gpg`:

    machine www.hamqth.com login MYCALL password SECRET

using `xmldata.qrz.com` for QRZ.com.

Separately, "QSO Callsign Lookup DXCC" works out country, continent and zones
from the callsign itself, for any callsign in the world, with no account and no
network connection. It reads a `cty.dat` country file named by "QSO Country
File"; these are published at <https://www.country-files.com>. It cannot supply
an operator's name, only where the station is.

## Reading Frequency and Mode From the Radio (optional)

FREQ, MODE and SUBMODE can be read from a transceiver through
[Hamlib](https://hamlib.github.io/), so they follow the radio as you tune or
change mode. This is off by default.

1. Install Hamlib and start its `rigctld` daemon against your radio. Example
   (FTDX10):

   ```
   rigctld -m 1042 -r /dev/ttyUSB0 -s 38400
   ```

   Run `rigctl -l` to find the model number (`-m`) for your radio. `rigctld` is
   used rather than a direct serial connection so that the radio can be shared
   with other software (WSJT-X, fldigi, and so on) and so that reading it never
   blocks Emacs.
2. Turn on "QSO Hamlib Enable" in the QSO customization group, and set the host
   and port if `rigctld` is not on the default `localhost:4532`.
3. Add FREQ, MODE and optionally SUBMODE to the form fields so that the values
   are visible while logging. SUBMODE is written to the ADIF record whether or
   not it appears on the form.
4. Within the form, `C-c C-r` reads the radio once and `C-c C-t` turns
   synchronization on or off.

A line under the title reports the link:

    IC-7300  localhost:4532  connected  14.074000 MHz  USB

It is headed by the model name the radio reports, so it names the radio rather
than saying "Rig". A `rigctld` too old to answer for its capabilities leaves it
reading "Rig". The frequency and mode shown there come straight from the radio
and are never edited, so they stay accurate even where a field has been typed
over, and connection trouble is reported rather than passed over in silence.
"QSO Hamlib Status Line" turns the line off.

If `rigctld` is not running, the form works exactly as it always has and the
line says so.

### How fields are filled in

A field is updated only when it is empty or still holds the value the radio
last put there, and never while the cursor is inside it, so anything you type
is left alone. Clearing a field hands it back to the radio, which is what makes
"clear after submission" work with a rig that is tuned between contacts.

Hamlib mode names are translated into ADIF MODE and SUBMODE values through the
customizable "QSO Hamlib Mode Map". For example `USB` is logged as MODE `SSB`
with SUBMODE `USB`, and `CWR` is logged as MODE `CW`.

The packet modes (`PKTUSB`, `PKTLSB`, `PKTFM`) map to nothing by default. The
radio reports only that it is in a data mode and cannot know whether you are
running FT8, JS8, PSK31 or anything else, so guessing would file contacts under
the wrong mode. If you work one digital mode for a whole session, set `PKTUSB`
to that mode in the mode map and it will be filled in automatically.

## Editing a Log

[adif-mode](https://github.com/K6SM/adif-mode) reads and edits ADIF files
without disturbing the field lengths the format records. qso.el requires it,
and MELPA installs it along with qso.
