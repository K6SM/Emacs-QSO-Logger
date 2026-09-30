;;; qso.el --- Amateur radio QSO logging -*- lexical-binding: t; -*-

;; Copyright (C) 2026, David Pentrack
;; Author: David Pentrack
;; URL: https://github.com/K6SM/Emacs-QSO-Logger
;; Keywords: comm, hamradio, adif, logging
;; Version: 1.3.9

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Package-Requires: ((emacs "25.1") (adif "1.0.7"))

;;; Commentary:

;; This LISP code provides some basic functions for Emacs to rapidly
;; capture and log amateur radio contacts (QSOs) into an ADIF file.
;;
;; qso.el provides a fuction that generates a customizable, dynamic
;; form (qso-log-form) to log amateur radio QSOs using almost any
;; combination of ADIF fields.  The choices offered for enumerated
;; fields, and the format of the log it writes, come from the adif
;; package, so they follow the ADIF specification that package follows.
;; This allows the user to customize the form for use in contests or
;; general logging.  All customizations are accessible in the "QSO"
;; group, whose parent is the Emacs "Applications" group, accessed
;; with M-x customize.
;;
;; Further processing of the logs can be done within Emacs or by
;; importing the ADIF file into another logging program.

;; Features

;; - Simple, customizable text interface for real-time ham radio QSO
;;   logging or even to rapidly convert paper log entries to an ADIF
;; - Runs entirely in a Linux terminal environment, allowing for its
;;   use in ultra-light, low-power HW/SW configurations (e.g. terminal-
;;   only mode on a Raspberry Pi Zero 2W)
;; - No mouse required (using tab or shift-tab to change fields or
;;   hover over buttons)
;; - Log entries are appended to a user-specified ADIF log file
;; - Any field in the ADIF specification can be selected to
;;   appear on the form, in whatever order is desired
;; - Each field has an option to preserve the most recent information
;;   after a QSO submission
;;   - Example: For situations where frequency and mode unchanged
;;     between QSOs
;;   - Also useful for repeating sent information reports in contests
;; - Automatically populates BAND based on FREQ for commonly used
;;   bands, if otherwise left blank or not shown on the form
;; - Optional live radio synchronization through Hamlib's rigctld:
;;   FREQ, MODE and SUBMODE follow the radio as the operator tunes
;;   or changes mode, and the current reading is shown in the header
;;   line above the form
;; - Option to lookup callsign information and show the information
;;   (text) in another buffer (requires an internet connection)
;; - Callsigns can be looked up at callook.info, HamQTH or QRZ.com,
;;   and the fields worth keeping can be filled in automatically,
;;   whether or not they appear on the form
;; - Country, continent and CQ/ITU zones can be worked out from the
;;   callsign itself using a cty.dat country file, which covers the
;;   whole world with no network connection and no account
;; - Option to check the log for duplicates before recording the QSO
;; - Option to clear the form without saving the information (e.g.
;;   for incomplete QSOs)
;;
;; Getting Started
;;
;;  1) Execute M-x customize, select "Applications" and then select
;;     "QSO" to see the customization options.
;;  2) Enter your callsign in the QSO Operator field.
;;  3) Enter the path to the ADIF file you will be using
;;     (e.g. ~/qsolog.adi).
;;  4) Add, remove, or reorder the fields you wish to have on the form.
;;  5) Select or deselect form fields that you wish you have cleared
;;     after a QSO submission (especially helpful for contests).
;;  6) Click "Apply" or "Apply and Save" as appropriate.
;;  7) Execute M-x qso-log-form to bring up and begin using the log
;;     entry form.
;;
;; Reading Frequency and Mode From the Radio (optional)
;;
;;  1) Install Hamlib and start its rigctld daemon against your radio,
;;     for example:
;;
;;       rigctld -m 3073 -r /dev/ttyUSB0 -s 38400
;;
;;     Run "rigctl -l" to find the model number (-m) for your radio.
;;     rigctld is used rather than a direct serial connection so that
;;     this package can share the radio with other software (WSJT-X,
;;     fldigi, and so on) and so that polling never blocks Emacs.
;;  2) Turn on "QSO Hamlib Enable" in the QSO customization group, and
;;     set the host and port if rigctld is not on the default
;;     localhost:4532.
;;  3) Add FREQ, MODE and (optionally) SUBMODE to the form fields so
;;     that the values are visible while logging.  SUBMODE is written
;;     to the ADIF record whether or not it appears on the form.
;;  4) Within the form, C-c C-r reads the radio once and C-c C-t turns
;;     synchronization on or off.
;;
;; The radio's line at the top of the form is headed by the model name
;; the radio reports, so it reads "IC-7300  localhost:4532  connected"
;; rather than "Rig".  A rigctld too old to answer for its capabilities
;; leaves the line saying "Rig", as before.
;;
;; While synchronization is running, a field is updated only when it is
;; empty or still holds the value the radio last put there, so anything
;; typed by the operator is never overwritten.
;;
;; Looking Up Callsigns (optional)
;;
;; "QSO Callsign Lookup Source" chooses where details come from:
;;
;;   callook.info  United States only, no account needed.  This is the
;;                 default, and it serves the FCC's public database.
;;   HamQTH        Worldwide, free, but asks you to register.
;;   QRZ.com       Worldwide, needs a paid XML subscription.
;;
;; Most countries outside the United States do not publish operator
;; names and addresses at all, which is why a worldwide lookup means
;; using a community-maintained callbook rather than an official
;; register.
;;
;; HamQTH and QRZ.com need a login.  Put the username in "QSO Callsign
;; Lookup User" and the password in ~/.authinfo.gpg, so that it is not
;; kept in your Emacs configuration:
;;
;;   machine www.hamqth.com login MYCALL password SECRET
;;   machine xmldata.qrz.com login MYCALL password SECRET
;;
;; "QSO Callsign Lookup Fields" chooses what to fill in.  A field is
;; filled whether or not it is on the form: anything not on the form is
;; written straight into the ADIF record when the QSO is submitted.
;;
;; Country, continent and CQ/ITU zones can also be worked out from the
;; callsign alone, with no network connection and no account, for any
;; callsign in the world.  Download a country file from
;; https://www.country-files.com, point "QSO Country File" at it, and
;; leave "QSO Callsign Lookup DXCC" on.  Whatever the chosen source
;; reports takes precedence over this, and if the file is missing the
;; rest of the form carries on as usual.
;;
;; Within the form, C-c C-l looks up the callsign that has been typed.

;;; Code:

(require 'wid-edit)
(require 'cl-lib)
(require 'subr-x)
(require 'seq)
(require 'url)
(require 'json)
(require 'xml)
(require 'easymenu)
(require 'adif)

(defgroup qso nil
  "Amateur radio QSO logging."
  :tag "QSO"
  :group 'applications)

(defcustom qso-adif-path "~/qso-log.adi"
  "Path to QSO ADIF file."
  :tag "QSO ADIF Path"
  :type 'string
  :group 'qso)

(defconst qso-program-version "1.3.9"
  "This package's version, written as PROGRAMVERSION in a new log's header.")

(defcustom qso-adif-title "Generated by Emacs QSO Logger"
  "Title of the ADIF file to appear in the first line of the ADIF header."
  :tag "QSO ADIF Title"
  :type 'string
  :group 'qso)

(defcustom qso-call-lookup t
  "If non-nil, provide a callsign lookup function/button."
  :tag "QSO Callsign Lookup"
  :type 'boolean
  :group 'qso)

;; Declared ahead of the option itself so that a setting saved under the
;; old name is carried over rather than quietly ignored.
(define-obsolete-variable-alias 'qso-call-lookup-autofill-name
  'qso-call-lookup-autofill "1.3.0")

(defcustom qso-call-lookup-autofill nil
  "If non-nil, provide a callsign lookup/autofill function/button."
  :tag "QSO Callsign Lookup Autofill"
  :type 'boolean
  :group 'qso)

(defcustom qso-call-lookup-source 'callook
  "Where to look up callsign details.

callook.info serves the FCC's public database and needs no account, but
it knows only United States callsigns.  Most other countries do not
publish operator details at all, so worldwide lookup means using a
community-maintained callbook, and those ask you to identify yourself.

Whichever source is chosen, `qso-call-lookup-dxcc' can still name the
country, continent and zones for any callsign in the world without any
network connection at all."
  :tag "QSO Callsign Lookup Source"
  :type '(choice
          (const :tag "callook.info (United States only, no account)" callook)
          (const :tag "HamQTH (worldwide, free account required)" hamqth)
          (const :tag "QRZ.com (worldwide, paid XML subscription)" qrz)
          (const :tag "None (offline country lookup only)" nil))
  :group 'qso)

(defcustom qso-call-lookup-user ""
  "Username or callsign used to log in to HamQTH or QRZ.com.

The matching password is read with `auth-source', so it never has to be
stored in your Emacs configuration.  Put a line like this one in
~/.authinfo.gpg:

    machine www.hamqth.com login MYCALL password SECRET

using machine `xmldata.qrz.com' for QRZ.com instead."
  :tag "QSO Callsign Lookup User"
  :type 'string
  :group 'qso)

(defcustom qso-call-lookup-fields '(NAME)
  "ADIF fields to fill in from a callsign lookup.

A field is filled in whether or not it appears on the form: anything
that is not on the form is written straight to the ADIF record when the
QSO is submitted.  Which fields actually arrive depends on the source,
and nothing is ever written over something you typed yourself."
  :tag "QSO Callsign Lookup Fields"
  :type '(set (const :tag "NAME (operator's name)" NAME)
              (const :tag "QTH (city or town)" QTH)
              (const :tag "GRIDSQUARE (Maidenhead locator)" GRIDSQUARE)
              (const :tag "STATE (primary subdivision)" STATE)
              (const :tag "CNTY (secondary subdivision)" CNTY)
              (const :tag "COUNTRY (DXCC entity name)" COUNTRY)
              (const :tag "CQZ (CQ zone)" CQZ)
              (const :tag "ITUZ (ITU zone)" ITUZ)
              (const :tag "CONT (continent)" CONT)
              (const :tag "LAT (latitude)" LAT)
              (const :tag "LON (longitude)" LON))
  :group 'qso)

(defcustom qso-call-lookup-timeout 10
  "Seconds to wait for a callsign lookup before giving up."
  :tag "QSO Callsign Lookup Timeout"
  :type 'number
  :group 'qso)

(defcustom qso-call-lookup-dxcc t
  "If non-nil, work out country, continent and zones from the callsign.

This reads the country file named by `qso-cty-file' and needs no network
connection and no account, so it covers every callsign in the world.  It
cannot supply an operator's name, only where the station is."
  :tag "QSO Callsign Lookup DXCC"
  :type 'boolean
  :group 'qso)

(defcustom qso-cty-file nil
  "Path to a cty.dat country file, or nil.

Country files are published at https://www.country-files.com and are
updated as new entities and prefixes are allocated.  When this is nil,
or names a file that is not there, callsigns are simply not resolved to
a country and the rest of the form carries on as usual."
  :tag "QSO Country File"
  :type '(choice (const :tag "None" nil) (file :tag "cty.dat"))
  :group 'qso)

(defcustom qso-call-duplicates t
  "Enable duplicate callsign checking."
  :tag "QSO Call Duplicates"
  :type 'boolean
  :group 'qso)

(defcustom qso-OPERATOR "MYCALL"
  "Control operator's callsign."
  :tag "QSO Operator"
  :type 'string
  :group 'qso)

(defconst qso-form-buffer-name "*QSO Log Entry*"
  "Name of the buffer holding the QSO log entry form.")

(defcustom qso-hamlib-enable nil
  "If non-nil, follow the radio's frequency and mode through Hamlib.

`qso-log-form' opens a connection to a running rigctld daemon and
polls it every `qso-hamlib-poll-interval' seconds, keeping the FREQ,
MODE and SUBMODE fields in step with the radio and showing the current
reading in the header line.

This requires rigctld to be running already, for example:

    rigctld -m 3073 -r /dev/ttyUSB0 -s 38400

Run \"rigctl -l\" to find the model number for your radio."
  :tag "QSO Hamlib Enable"
  :type 'boolean
  :group 'qso)

(defcustom qso-hamlib-host "localhost"
  "Host running the rigctld daemon."
  :tag "QSO Hamlib Host"
  :type 'string
  :group 'qso)

(defcustom qso-hamlib-port 4532
  "TCP port on which the rigctld daemon is listening."
  :tag "QSO Hamlib Port"
  :type 'integer
  :group 'qso)

(defcustom qso-hamlib-poll-interval 1.0
  "Seconds between readings of the radio's frequency and mode."
  :tag "QSO Hamlib Poll Interval"
  :type 'number
  :group 'qso)

(defcustom qso-hamlib-reconnect-interval 5.0
  "Seconds to wait before retrying a failed connection to rigctld."
  :tag "QSO Hamlib Reconnect Interval"
  :type 'number
  :group 'qso)

(defcustom qso-hamlib-connect-timeout 5.0
  "Seconds to allow rigctld to answer a connection attempt.

A host that is switched off or behind a firewall may never answer at
all.  Connecting does not block Emacs, but without a deadline of this
kind the form would sit indefinitely reporting that it is connecting."
  :tag "QSO Hamlib Connect Timeout"
  :type 'number
  :group 'qso)

(define-obsolete-variable-alias 'qso-hamlib-header-line
  'qso-hamlib-status-line "1.3.1")

(defcustom qso-hamlib-status-line t
  "If non-nil, show the state of the radio link at the top of the form.

The line reports the radio directly and is never edited, so it stays
accurate even where the operator has typed over the FREQ or MODE field.
It says the same thing, in the same colours, as the line `ham-rig'
shows at the top of its own panel."
  :tag "QSO Hamlib Status Line"
  :type 'boolean
  :group 'qso)

(defcustom qso-hamlib-freq-format "%.6f"
  "Format string used to render the radio's frequency in MHz."
  :tag "QSO Hamlib Frequency Format"
  :type 'string
  :group 'qso)

(defcustom qso-hamlib-mode-alist
  '(("USB"     "SSB"  "USB")
    ("LSB"     "SSB"  "LSB")
    ("ECSSUSB" "SSB"  "USB")
    ("ECSSLSB" "SSB"  "LSB")
    ("CW"      "CW"   "")
    ("CWR"     "CW"   "")
    ("RTTY"    "RTTY" "")
    ("RTTYR"   "RTTY" "")
    ("AM"      "AM"   "")
    ("AMS"     "AM"   "")
    ("SAM"     "AM"   "")
    ("SAL"     "AM"   "")
    ("SAH"     "AM"   "")
    ("DSB"     "AM"   "")
    ("FM"      "FM"   "")
    ("FMN"     "FM"   "")
    ("WFM"     "FM"   "")
    ("PKTUSB"  ""     "")
    ("PKTLSB"  ""     "")
    ("PKTFM"   ""     ""))
  "How Hamlib mode names translate into ADIF MODE and SUBMODE values.

Each entry is a Hamlib mode name followed by the ADIF MODE and ADIF
SUBMODE to record for it.  An empty string means \"leave the field
alone\".

The packet modes are deliberately left empty: the radio reports only
that it is in a data mode and cannot know whether the operator is
running FT8, JS8, PSK31 or anything else, so guessing would file
contacts under the wrong mode.  An operator who works one digital mode
for a whole session can set PKTUSB to that mode here, for example
\"FT8\", and have it filled in automatically."
  :tag "QSO Hamlib Mode Map"
  :type '(alist :key-type (string :tag "Hamlib mode")
                :value-type (group (string :tag "ADIF MODE")
                                   (string :tag "ADIF SUBMODE")))
  :group 'qso)

(defun qso--field-choice-type ()
  "Return a customize type offering every field the form can show.

The names are the adif package's `adif-field-names', so a field a newer
adif knows about is offered without a change here, and anything else,
an APP_ field for instance, can still be typed in.  OPERATOR is left
out, being written from `qso-OPERATOR' with every record, and so are the
fields ADIF allows only in old logs."
  `(choice ,@(mapcar (lambda (f) (list 'const :tag f (intern f)))
                     (seq-remove (lambda (f)
                                   (or (string= f "OPERATOR")
                                       ;; This runs as the package loads,
                                       ;; so an older adif must not stop it
                                       ;; there: `qso-log-form' explains.
                                       (and (fboundp 'adif-field-import-only-p)
                                            (adif-field-import-only-p f))))
                                 adif-field-names))
           (const :tag "Custom Choice" custom-choice)
           (symbol :tag "Other field")))

(defcustom qso-form-fields
  '((CALL . t)
    (NAME . t)
    (RST_RCVD . t)
    (RST_SENT . nil)
    (FREQ . nil)
    (MODE . nil)
    (COMMENT . t))
  "Fields to show in the QSO Log Entry form and which to clear between entries."
  :tag "QSO Form Fields"
  :type `(alist :key-type ,(qso--field-choice-type)
                :value-type (boolean :tag "Clear after submission"))
  :group 'qso)

(defcustom qso-field-widths
  '((AGE . 3) (ALTITUDE . 4) (ANT_AZ . 3) (ANT_EL . 3) (ARRL_SECT . 3)
    (A_INDEX . 3) (CALL . 10) (CLASS . 10) (COMMENT . 37) (COMMENT_INTL . 32)
    (CONT . 2) (CONTACTED_OP . 32) (COUNTRY . 37) (COUNTRY_INTL . 32)
    (EMAIL . 39) (FREQ . 10) (FREQ_RX . 10) (GRIDSQUARE . 6)
    (GRIDSQUARE_EXT . 6) (GUEST_OP . 36) (K_INDEX . 3) (LAT . 11) (LON . 11)
    (MY_ARRL_SECT . 3) (OWNER_CALLSIGN . 10) (QSLRDATE . 8) (QSLSDATE . 8)
    (QSL_RCVD . 1) (QSL_RCVD_VIA . 1) (QSL_SENT . 1) (QSL_SENT_VIA . 1)
    (QSO_COMPLETE . 3) (QSO_DATE . 8) (QSO_DATE_OFF . 8) (QSO_RANDOM . 1)
    (RST_RCVD . 6) (RST_SENT . 6) (RX_PWR . 6) (SILENT_KEY . 1) (SRX . 6)
    (SWL . 1) (TEN_TEN . 6) (TIME_OFF . 6) (TIME_ON . 6) (TX_PWR . 6)
    (WEB . 41))
  "Width in characters of each field's entry area on the form.
A field not listed is `qso-field-default-width' wide.  A field shown as
a menu takes the width of whatever is chosen, so its entry here is used
only when it is typed into instead; see `qso-menu-choice-limit'."
  :tag "QSO Field Widths"
  :type `(alist :key-type ,(qso--field-choice-type)
                :value-type (integer :tag "Width"))
  :group 'qso)

(defcustom qso-field-default-width 40
  "Width in characters of a field not listed in `qso-field-widths'."
  :tag "QSO Field Default Width"
  :type 'integer
  :group 'qso)

(defcustom qso-menu-choice-limit 35
  "Most values a field may have and still be offered as a menu.

A field whose values the adif package lists is a menu when there are
this many or fewer of them.  With more, the field is typed into, and
\\<widget-field-keymap>\\[widget-complete] completes what has been typed from the same list,
showing each value's meaning alongside."
  :tag "QSO Menu Choice Limit"
  :type 'integer
  :group 'qso)

(defvar qso-form-field-definitions
  '((custom-choice . (menu-choice :tag "Choose" :format "Choose: %[%v%]\n" :value "This"
                                  :help-echo "Choose me, please!"
                                  :notify (lambda (widget &rest ignore)
                                            (message "%s is a good choice!"
                                                     (widget-value widget)))
                                  (item :tag "This option" :value "This")
                                  (item :tag "That option" :value "That")
                                  (editable-field :menu-tag "No option" :value "Thus option"))))
  "Widget definitions that replace the form's own, by field.

Each entry is (FIELD . (TYPE ARGS...)), handed to `widget-create'.  A
field without an entry here is drawn by `qso--field-definition', from
what the adif package knows of it.  A menu-choice given no choices of
its own offers the values adif lists for its field.")


;;; Radio synchronization through Hamlib's rigctld

;; rigctld speaks a line oriented protocol on a TCP socket.  Prefixing a
;; command with "+" selects its extended response, which names each value
;; and terminates the reply with an "RPRT" status line, so a reply can be
;; recognized as complete no matter how the operating system splits it
;; across packets.  Asking for both values at once looks like this:
;;
;;     +\get_freq            get_freq:
;;                           Frequency: 14074000
;;                           RPRT 0
;;     +\get_mode            get_mode:
;;                           Mode: USB
;;                           Passband: 2400
;;                           RPRT 0

(defconst qso--hamlib-query "+\\get_freq\n+\\get_mode\n"
  "Commands sent to rigctld to read the current frequency and mode.")

(defconst qso--hamlib-caps-query "+\\dump_caps\n"
  "Command sent to rigctld once per connection to learn what radio it drives.

The reply is long, and among it are the two lines this package wants:

    Model name:             IC-7300
    Mfg name:               Icom

It is asked for once, when the connection opens, rather than on every
poll.  A rigctld too old to know the command answers with a failing
RPRT, which leaves the radio unnamed and nothing else disturbed.")

(defvar qso--hamlib-process nil
  "Network connection to rigctld, or nil when not connected.")

(defvar qso--hamlib-timer nil
  "Repeating timer that polls the radio, or nil when not polling.")

(defvar qso--hamlib-pending ""
  "Text received from rigctld that does not yet form a complete line.")

(defvar qso--hamlib-freq nil
  "Frequency most recently reported by the radio, in hertz.")

(defvar qso--hamlib-rig-mode nil
  "Mode name most recently reported by the radio, as a Hamlib string.")

(defvar qso--hamlib-model nil
  "Model name of the radio rigctld is driving, or nil when not known.
Read from the radio's capabilities when the connection opens.")

(defvar qso--hamlib-mfg nil
  "Manufacturer of the radio rigctld is driving, or nil when not known.")

(defvar qso--hamlib-awaiting-caps nil
  "Non-nil while the reply to `qso--hamlib-caps-query' is still arriving.

The capabilities dump runs to hundreds of lines and is answered before
anything else on the same connection, so it is read on its own terms:
while this is set, only the two lines wanted are looked at and the
closing RPRT is not mistaken for the end of a frequency reading.")

(defvar qso--hamlib-error nil
  "Description of the most recent radio communication failure, or nil.")

(defvar qso--hamlib-next-retry 0
  "Time, as returned by `float-time', before which not to redial rigctld.")

(defvar qso--hamlib-state 'idle
  "How the connection to rigctld currently stands.
One of `idle', `connecting', `connected' or `disconnected'.")

(defvar qso--hamlib-connect-timer nil
  "Timer that gives up on a connection attempt, or nil.")

(defvar qso--hamlib-inhibit nil
  "When non-nil, leave the form alone even if a new reading arrives.
Bound while a QSO is being submitted or cleared so that the poller
cannot rearrange widgets underneath those operations.")

(defvar-local qso--widget-alist nil
  "Widgets of the form in this buffer, as (FIELD WIDGET CLEAR-AFTER-SUBMIT).
`qso-log-form' keeps this so that the radio poller, which runs long
after the form was built, can find the live widgets.")

(defvar-local qso--hamlib-written nil
  "Values this package last wrote into form fields, as (FIELD . VALUE).
Used to tell a field the radio filled in from one the operator typed.")

(defun qso--hamlib-live-p ()
  "Return non-nil when the connection to rigctld is usable."
  (and (eq qso--hamlib-state 'connected)
       qso--hamlib-process
       (process-live-p qso--hamlib-process)))

(defun qso--hamlib-cancel-connect-timer ()
  "Stop waiting for an answer to a connection attempt."
  (when qso--hamlib-connect-timer
    (cancel-timer qso--hamlib-connect-timer)
    (setq qso--hamlib-connect-timer nil)))

(defun qso--hamlib-discard-process ()
  "Drop the connection to rigctld without treating it as a failure."
  (qso--hamlib-cancel-connect-timer)
  (when qso--hamlib-process
    ;; Detach the callbacks first, so that deleting the process does not
    ;; come back through the sentinel as a fresh failure.
    (set-process-sentinel qso--hamlib-process #'ignore)
    (set-process-filter qso--hamlib-process #'ignore)
    (ignore-errors (delete-process qso--hamlib-process)))
  (setq qso--hamlib-process nil))

(defun qso--hamlib-forget-rig ()
  "Forget which radio rigctld was driving.
Called whenever the link goes, so that the name on the status line
always belongs to the connection currently open."
  (setq qso--hamlib-model nil)
  (setq qso--hamlib-mfg nil)
  (setq qso--hamlib-awaiting-caps nil))

(defun qso--hamlib-failed (reason)
  "Record REASON for losing the radio and arrange to try again later."
  (qso--hamlib-discard-process)
  (setq qso--hamlib-state 'disconnected)
  (setq qso--hamlib-error reason)
  (setq qso--hamlib-pending "")
  (setq qso--hamlib-freq nil)
  (setq qso--hamlib-rig-mode nil)
  (qso--hamlib-forget-rig)
  (setq qso--hamlib-next-retry (+ (float-time) qso-hamlib-reconnect-interval))
  (qso--hamlib-update-status-line))

(defun qso--hamlib-connect ()
  "Begin connecting to rigctld.

This returns at once, whatever the state of the network.  The socket is
opened with `:nowait', so a host that is switched off or firewalled is
noticed by the sentinel or by `qso--hamlib-connect-timer' rather than by
making Emacs wait out the operating system's TCP timeout."
  (qso--hamlib-discard-process)
  (setq qso--hamlib-pending "")
  (setq qso--hamlib-state 'connecting)
  (setq qso--hamlib-error nil)
  (condition-case err
      (setq qso--hamlib-process
            (make-network-process :name "qso-rigctld"
                                  :host qso-hamlib-host
                                  :service qso-hamlib-port
                                  :nowait t
                                  :noquery t
                                  :coding 'utf-8-unix
                                  :filter #'qso--hamlib-filter
                                  :sentinel #'qso--hamlib-sentinel))
    (error
     (setq qso--hamlib-process nil)
     (qso--hamlib-failed (error-message-string err))))
  ;; A host that drops packets outright never answers at all, so give the
  ;; attempt a deadline of our own rather than waiting on the network stack.
  (when (eq qso--hamlib-state 'connecting)
    (setq qso--hamlib-connect-timer
          (run-at-time qso-hamlib-connect-timeout nil
                       #'qso--hamlib-connect-expired)))
  (qso--hamlib-update-status-line))

(defun qso--hamlib-connect-expired ()
  "Give up on a connection attempt that rigctld never answered."
  (setq qso--hamlib-connect-timer nil)
  (when (eq qso--hamlib-state 'connecting)
    (qso--hamlib-failed
     (format "no answer within %g s" qso-hamlib-connect-timeout))))

(defun qso--hamlib-disconnect ()
  "Close the connection to rigctld, if any."
  (qso--hamlib-discard-process)
  (setq qso--hamlib-state 'idle))

(defun qso--hamlib-sentinel (process event)
  "Follow the connection to rigctld as it reports EVENT for PROCESS."
  (when (eq process qso--hamlib-process)
    (if (string-prefix-p "open" event)
        (progn
          (qso--hamlib-cancel-connect-timer)
          (setq qso--hamlib-state 'connected)
          (setq qso--hamlib-error nil)
          ;; Ask what radio this is before asking what it is doing.
          ;; rigctld answers in the order it is asked, so the capabilities
          ;; are complete before the first reading arrives.
          (setq qso--hamlib-awaiting-caps t)
          (ignore-errors
            (process-send-string process qso--hamlib-caps-query)
            (process-send-string process qso--hamlib-query))
          (qso--hamlib-update-status-line))
      (qso--hamlib-failed (string-trim event)))))

(defun qso--hamlib-filter (_process string)
  "Split STRING arriving from rigctld into whole lines and act on each."
  (setq qso--hamlib-pending (concat qso--hamlib-pending string))
  (while (string-match "\\`\\([^\n]*\\)\n" qso--hamlib-pending)
    (let ((line (match-string 1 qso--hamlib-pending)))
      (setq qso--hamlib-pending
            (substring qso--hamlib-pending (match-end 0)))
      (qso--hamlib-handle-line (string-trim line)))))

(defun qso--hamlib-handle-line (line)
  "Interpret a single response LINE from rigctld."
  (cond
   ;; The capabilities dump, read on its own and not confused with a
   ;; reading.  Its RPRT closes it and nothing else in it is wanted.
   (qso--hamlib-awaiting-caps
    (cond
     ((string-match "\\`Model name:[ \t]*\\(.+\\)\\'" line)
      (setq qso--hamlib-model (string-trim (match-string 1 line))))
     ((string-match "\\`Mfg name:[ \t]*\\(.+\\)\\'" line)
      (setq qso--hamlib-mfg (string-trim (match-string 1 line))))
     ((string-match "\\`RPRT \\(-?[0-9]+\\)\\'" line)
      (setq qso--hamlib-awaiting-caps nil)
      (qso--hamlib-update-status-line))))
   ((string-match "\\`Frequency: \\([0-9]+\\)\\'" line)
    (setq qso--hamlib-freq (string-to-number (match-string 1 line))))
   ((string-match "\\`Mode: \\([A-Za-z0-9_-]+\\)\\'" line)
    (setq qso--hamlib-rig-mode (match-string 1 line)))
   ((string-match "\\`RPRT \\(-?[0-9]+\\)\\'" line)
    ;; A response is complete; a nonzero status means the radio refused it.
    (let ((status (string-to-number (match-string 1 line))))
      (setq qso--hamlib-error
            (unless (zerop status) (format "rigctld status %d" status))))
    (qso--hamlib-apply))))

(defun qso--hamlib-poll ()
  "Read the radio, redialing first if the link has dropped."
  (cond
   ((qso--hamlib-live-p)
    (condition-case err
        (process-send-string qso--hamlib-process qso--hamlib-query)
      (error (qso--hamlib-failed (error-message-string err)))))
   ;; An attempt already under way answers through the sentinel or times
   ;; out on its own; starting another would just pile up sockets.
   ((eq qso--hamlib-state 'connecting) nil)
   ;; Redial no more often than `qso-hamlib-reconnect-interval', so that a
   ;; radio that is switched off does not produce a stream of failures.
   ((>= (float-time) qso--hamlib-next-retry)
    (qso--hamlib-connect)))
  (qso--hamlib-update-status-line))

(defun qso--hamlib-freq-string ()
  "Return the radio's frequency in MHz as a string, or nil if unknown."
  (when (and qso--hamlib-freq (> qso--hamlib-freq 0))
    (format qso-hamlib-freq-format (/ qso--hamlib-freq 1000000.0))))

(defun qso--band-for-freq (freq)
  "Return the ADIF band holding FREQ, a string in MHz, or nil."
  (when freq
    (let ((freq (string-to-number freq)))
      (cond
       ((and (>= freq 1.8) (<= freq 2.0)) "160m")
       ((and (>= freq 3.5) (<= freq 4.0)) "80m")
       ((and (>= freq 5.3305) (<= freq 5.405)) "60m")
       ((and (>= freq 7.0) (<= freq 7.3)) "40m")
       ((and (>= freq 10.1) (<= freq 10.15)) "30m")
       ((and (>= freq 14.0) (<= freq 14.35)) "20m")
       ((and (>= freq 18.068) (<= freq 18.168)) "17m")
       ((and (>= freq 21.0) (<= freq 21.45)) "15m")
       ((and (>= freq 24.89) (<= freq 24.99)) "12m")
       ((and (>= freq 28.0) (<= freq 29.7)) "10m")
       ((and (>= freq 50.0) (<= freq 54.0)) "6m")
       ((and (>= freq 144.0) (<= freq 148.0)) "2m")
       ((and (>= freq 219.0) (<= freq 225.0)) "1.25m")
       ((and (>= freq 430.0) (<= freq 450.0)) "70cm")
       (t nil)))))

(defun qso--hamlib-adif-mode ()
  "Return (MODE . SUBMODE) in ADIF terms for the radio's mode, or nil.
Either element may be an empty string, meaning the radio's mode does not
determine that field."
  (when qso--hamlib-rig-mode
    (let ((entry (assoc-string qso--hamlib-rig-mode qso-hamlib-mode-alist t)))
      (when entry (cons (nth 1 entry) (nth 2 entry))))))

(defun qso--widget-accepts-p (widget value)
  "Return non-nil when WIDGET can hold VALUE.
A menu-choice only offers a fixed set of values, so setting it to
anything else would leave the form displaying a value the operator
cannot see or correct."
  (if (eq (widget-type widget) 'menu-choice)
      (let ((offered nil))
        (dolist (choice (widget-get widget :args))
          (when (ignore-errors (widget-apply choice :match value))
            (setq offered t)))
        offered)
    t))

(defun qso--hamlib-point-in-widget-p (widget)
  "Return non-nil when point lies within WIDGET."
  (let ((from (widget-get widget :from))
        (to (widget-get widget :to)))
    (and (markerp from)
         (markerp to)
         (>= (point) (marker-position from))
         (<= (point) (marker-position to)))))

(defun qso--hamlib-set-field (field value)
  "Set FIELD's widget to VALUE, unless the operator owns the field.
Return non-nil when the widget was changed.  A field is left alone when
it holds anything other than what the radio last put there, and while
point is inside it, so typing is never overwritten.

An empty VALUE clears a field this package filled in earlier, which is
what keeps a SUBMODE of USB from surviving a switch from SSB to CW.  A
VALUE of nil means the radio said nothing about this field and leaves it
untouched."
  (let ((widget (nth 1 (assq field qso--widget-alist))))
    (when (and widget
               value
               (or (string-empty-p value)
                   (qso--widget-accepts-p widget value)))
      (let ((current (ignore-errors (widget-value widget)))
            (ours (cdr (assq field qso--hamlib-written))))
        (when (and (stringp current)
                   (not (equal current value))
                   (or (string-empty-p (string-trim current))
                       (equal current ours))
                   (not (qso--hamlib-point-in-widget-p widget)))
          (save-excursion
            (widget-value-set widget value))
          (let ((cell (assq field qso--hamlib-written)))
            (if cell
                (setcdr cell value)
              (push (cons field value) qso--hamlib-written)))
          t)))))

(defun qso--hamlib-apply ()
  "Push the latest reading into the QSO form and its header line."
  (let ((buffer (get-buffer qso-form-buffer-name)))
    (when (and (buffer-live-p buffer) (not qso--hamlib-inhibit))
      (with-current-buffer buffer
        (let* ((mode-pair (qso--hamlib-adif-mode))
               (changed nil))
          (when (qso--hamlib-set-field 'FREQ (qso--hamlib-freq-string))
            (setq changed t))
          (when (qso--hamlib-set-field 'MODE (car mode-pair))
            (setq changed t))
          (when (qso--hamlib-set-field 'SUBMODE (cdr mode-pair))
            (setq changed t))
          (when changed
            (widget-setup)
            (qso--fontify-labels))
          (qso--hamlib-update-status-line))))))

(defvar-local qso--status-start nil
  "Marker at the start of the radio status line, or nil.")

(defun qso--hamlib-rig-name ()
  "Return the radio's model name, or \"Rig\" until it is known.

The name comes from the radio itself, through `qso--hamlib-caps-query',
so it says IC-7300 rather than the model number given to rigctld.  Until
the reply arrives, and on a rigctld too old to answer, the line reads as
it always did."
  (or (and qso--hamlib-model
           (not (string-empty-p qso--hamlib-model))
           qso--hamlib-model)
      "Rig"))

(defun qso--hamlib-status-line ()
  "Return the one line describing the radio link.

Word for word and colour for colour the line `ham-rig' shows at the top
of its own panel, so one connection reads the same way in either
buffer, except that the radio names itself where `ham-rig' says Rig."
  (let* ((where (propertize (format "%s:%d" qso-hamlib-host qso-hamlib-port)
                            'face 'qso-label))
         (state
          (cond
           ((eq qso--hamlib-state 'connecting)
            (propertize "connecting" 'face 'qso-warn))
           ((qso--hamlib-live-p) (propertize "connected" 'face 'qso-ok))
           (t (propertize
               (let ((wait (and qso--hamlib-next-retry
                                (- qso--hamlib-next-retry (float-time)))))
                 (if (and wait (> wait 0))
                     (format "reconnecting in %.1fs" wait)
                   "not connected"))
               'face 'qso-danger))))
         (reading
          (when (and (qso--hamlib-live-p) qso--hamlib-freq)
            (concat "  " (propertize (or (qso--hamlib-freq-string) "?")
                                     'face 'qso-value)
                    " " (propertize "MHz" 'face 'qso-unit)
                    "  " (propertize (or qso--hamlib-rig-mode "?")
                                     'face 'qso-value)))))
    (concat (propertize (qso--hamlib-rig-name) 'face 'qso-label)
            "  " where "  " state
            (or reading ""))))

(defun qso--hamlib-update-status-line ()
  "Rewrite the radio status line in place near the top of the form.

The line sits in the buffer rather than in a header line, because
`ham-rig' has no header line and the two are meant to match.

Only the one line is replaced, and widget.el's change hooks are held
off while it happens: they scan for field boundaries on every edit, and
a rewrite in the middle of a form full of widgets otherwise looks to
them like a field being torn in half."
  (let ((buffer (get-buffer qso-form-buffer-name)))
    (when (and (buffer-live-p buffer) qso-hamlib-status-line)
      (with-current-buffer buffer
        (when (and (markerp qso--status-start)
                   (marker-position qso--status-start))
          (let ((inhibit-read-only t)
                (inhibit-modification-hooks t))
            (save-excursion
              (goto-char qso--status-start)
              (delete-region (line-beginning-position) (line-end-position))
              (insert (qso--hamlib-status-line)))))))))

(defun qso-hamlib-start ()
  "Start following the radio's frequency and mode through rigctld."
  (interactive)
  (qso--hamlib-cancel-timer)
  (setq qso--hamlib-next-retry 0)
  (qso--hamlib-connect)
  (setq qso--hamlib-timer
        (run-at-time 0 qso-hamlib-poll-interval #'qso--hamlib-poll))
  (message "QSO: following radio at %s:%d" qso-hamlib-host qso-hamlib-port))

(defun qso--hamlib-cancel-timer ()
  "Stop the polling timer, if it is running."
  (when qso--hamlib-timer
    (cancel-timer qso--hamlib-timer)
    (setq qso--hamlib-timer nil)))

(defun qso-hamlib-stop ()
  "Stop following the radio and close the connection to rigctld."
  (interactive)
  (qso--hamlib-cancel-timer)
  (qso--hamlib-disconnect)
  (setq qso--hamlib-pending "")
  (setq qso--hamlib-freq nil)
  (setq qso--hamlib-rig-mode nil)
  (setq qso--hamlib-error nil)
  (qso--hamlib-forget-rig)
  (setq qso--hamlib-next-retry 0)
  (qso--hamlib-update-status-line))

(defun qso-hamlib-toggle ()
  "Turn radio synchronization on or off for the rest of this session."
  (interactive)
  (if qso--hamlib-timer
      (progn
        (qso-hamlib-stop)
        (message "QSO: no longer following the radio"))
    (qso-hamlib-start)))

(defun qso-hamlib-sync-now ()
  "Read the radio once, whether or not synchronization is running."
  (interactive)
  (if (qso--hamlib-live-p)
      (condition-case err
          (process-send-string qso--hamlib-process qso--hamlib-query)
        (error (qso--hamlib-failed (error-message-string err))))
    ;; Connecting is asynchronous, so the reading is sent by the sentinel
    ;; once the connection actually opens.
    (setq qso--hamlib-next-retry 0)
    (qso--hamlib-connect)
    (message "QSO: contacting rigctld at %s:%d..."
             qso-hamlib-host qso-hamlib-port)))

;;; Callsign lookup

;; Every source is reduced to the same thing: an alist of ADIF field names
;; and values.  The form and the ADIF writer only ever see that alist, so
;; adding a source means writing one function and nothing else.

(defvar-local qso--lookup-extra nil
  "Looked-up fields that are not on the form, as (FIELD . VALUE).
Written into the ADIF record when the QSO is submitted.")

(defvar-local qso--lookup-call nil
  "Callsign that `qso--lookup-extra' belongs to.
Keeps details of one station out of the record of another.")

(defvar qso--lookup-session nil
  "Cached login session for the current lookup source, or nil.")

(defvar qso--lookup-session-time 0
  "When `qso--lookup-session' was obtained, as `float-time'.")

(defun qso--lookup-secret (host user)
  "Return the password stored for USER at HOST, or nil."
  (require 'auth-source)
  (let ((found (car (auth-source-search :host host :user user :max 1))))
    (when found
      (let ((secret (plist-get found :secret)))
        (if (functionp secret) (funcall secret) secret)))))

(defun qso--lookup-http-get (url)
  "Fetch URL and return its body as a string, or nil on any failure."
  (let ((buffer (condition-case nil
                    ;; The timeout argument arrived in Emacs 26; without it
                    ;; a stalled server would hang Emacs until it gave up.
                    (if (>= emacs-major-version 26)
                        (url-retrieve-synchronously url t t qso-call-lookup-timeout)
                      (url-retrieve-synchronously url t t))
                  (error nil))))
    (when (buffer-live-p buffer)
      (unwind-protect
          (with-current-buffer buffer
            (goto-char (point-min))
            (if (re-search-forward "^\r?$" nil t)
                (forward-line 1)
              (goto-char (point-min)))
            (decode-coding-string
             (buffer-substring-no-properties (point) (point-max)) 'utf-8))
        (kill-buffer buffer)))))

(defun qso--lookup-parse-xml (body)
  "Parse BODY as XML and return its root node, or nil."
  (ignore-errors
    (with-temp-buffer
      (insert body)
      (car (xml-parse-region (point-min) (point-max))))))

(defun qso--xml-text (node tag)
  "Return the text of TAG inside NODE, or nil."
  (let ((child (car (xml-get-children node tag))))
    (when child
      (let ((text (car (xml-node-children child))))
        (when (stringp text)
          (let ((trimmed (string-trim text)))
            (unless (string-empty-p trimmed) trimmed)))))))

(defun qso--lookup-clean (data)
  "Drop empty entries from DATA, an alist of ADIF fields."
  (let ((result '()))
    (dolist (pair data (nreverse result))
      (let ((value (cdr pair)))
        (when (and value (stringp value) (not (string-empty-p (string-trim value))))
          (push (cons (car pair) (string-trim value)) result))))))

;;; Source: callook.info (United States)

(defun qso--lookup-callook (call)
  "Look CALL up at callook.info.  Return an alist of ADIF fields."
  (let ((body (qso--lookup-http-get
               (format "https://callook.info/%s/json" (url-hexify-string call)))))
    (when body
      (let* ((json-object-type 'alist)
             (json-array-type 'list)
             (json-key-type 'symbol)
             (data (ignore-errors (json-read-from-string body))))
        (when (equal (cdr (assq 'status data)) "VALID")
          (let* ((address (cdr (assq 'address data)))
                 (location (cdr (assq 'location data)))
                 ;; "NEWINGTON, CT 06111" -- city before the comma, then
                 ;; the two-letter state.
                 (line2 (cdr (assq 'line2 address)))
                 (city (when line2 (car (split-string line2 ","))))
                 (state (when (and line2 (string-match ",\\s-*\\([A-Z]\\{2\\}\\)\\b" line2))
                          (match-string 1 line2))))
            (qso--lookup-clean
             (list (cons 'NAME (cdr (assq 'name data)))
                   (cons 'QTH city)
                   (cons 'STATE state)
                   (cons 'GRIDSQUARE (cdr (assq 'gridsquare location)))
                   (cons 'LAT (cdr (assq 'latitude location)))
                   (cons 'LON (cdr (assq 'longitude location)))
                   (cons 'COUNTRY "United States of America")))))))))

;;; Source: HamQTH (worldwide)

(defun qso--lookup-hamqth-session ()
  "Return a HamQTH session id, logging in if the cached one is stale."
  ;; HamQTH sessions last about an hour; renewing a little early is
  ;; cheaper than discovering the expiry in the middle of a contact.
  (if (and qso--lookup-session
           (< (- (float-time) qso--lookup-session-time) 3000))
      qso--lookup-session
    (let* ((user (string-trim (or qso-call-lookup-user "")))
           (password (unless (string-empty-p user)
                       (qso--lookup-secret "www.hamqth.com" user))))
      (cond
       ((string-empty-p user)
        (message "QSO: set QSO Callsign Lookup User to your HamQTH login")
        nil)
       ((null password)
        (message "QSO: no HamQTH password for %s in auth-source (~/.authinfo.gpg)" user)
        nil)
       (t
        (let ((body (qso--lookup-http-get
                     (format "https://www.hamqth.com/xml.php?u=%s&p=%s"
                             (url-hexify-string user)
                             (url-hexify-string password)))))
          (when body
            (let* ((root (qso--lookup-parse-xml body))
                   (session (car (xml-get-children root 'session)))
                   (id (and session (qso--xml-text session 'session_id)))
                   (problem (and session (qso--xml-text session 'error))))
              (cond
               (id (setq qso--lookup-session id
                         qso--lookup-session-time (float-time))
                   id)
               (problem (message "QSO: HamQTH: %s" problem) nil)
               (t (message "QSO: HamQTH did not return a session") nil))))))))))

(defun qso--lookup-hamqth (call)
  "Look CALL up at HamQTH.  Return an alist of ADIF fields."
  (let ((session (qso--lookup-hamqth-session)))
    (when session
      (let ((body (qso--lookup-http-get
                   (format "https://www.hamqth.com/xml.php?id=%s&callsign=%s&prg=Emacs-QSO-Logger"
                           (url-hexify-string session)
                           (url-hexify-string (downcase call))))))
        (when body
          (let* ((root (qso--lookup-parse-xml body))
                 (search (car (xml-get-children root 'search)))
                 (problem (qso--xml-text root 'session)))
            (cond
             (search
              (qso--lookup-clean
               (list (cons 'NAME (or (qso--xml-text search 'adr_name)
                                     (qso--xml-text search 'nick)))
                     (cons 'QTH (or (qso--xml-text search 'qth)
                                    (qso--xml-text search 'adr_city)))
                     (cons 'GRIDSQUARE (qso--xml-text search 'grid))
                     (cons 'STATE (qso--xml-text search 'us_state))
                     (cons 'CNTY (qso--xml-text search 'us_county))
                     (cons 'COUNTRY (qso--xml-text search 'country))
                     (cons 'CQZ (qso--xml-text search 'cq))
                     (cons 'ITUZ (qso--xml-text search 'itu))
                     (cons 'CONT (qso--xml-text search 'continent))
                     (cons 'LAT (qso--xml-text search 'latitude))
                     (cons 'LON (qso--xml-text search 'longitude)))))
             (t
              ;; A rejected session id is worth one silent retry, since it
              ;; simply means the hour ran out mid-session.
              (when problem (setq qso--lookup-session nil))
              nil))))))))

;;; Source: QRZ.com (worldwide, subscription)

(defun qso--lookup-qrz-session ()
  "Return a QRZ.com session key, logging in if the cached one is stale."
  (if (and qso--lookup-session
           (< (- (float-time) qso--lookup-session-time) 3000))
      qso--lookup-session
    (let* ((user (string-trim (or qso-call-lookup-user "")))
           (password (unless (string-empty-p user)
                       (qso--lookup-secret "xmldata.qrz.com" user))))
      (cond
       ((string-empty-p user)
        (message "QSO: set QSO Callsign Lookup User to your QRZ.com login")
        nil)
       ((null password)
        (message "QSO: no QRZ.com password for %s in auth-source (~/.authinfo.gpg)" user)
        nil)
       (t
        (let ((body (qso--lookup-http-get
                     (format "https://xmldata.qrz.com/xml/current/?username=%s;password=%s;agent=Emacs-QSO-Logger"
                             (url-hexify-string user)
                             (url-hexify-string password)))))
          (when body
            (let* ((root (qso--lookup-parse-xml body))
                   (session (car (xml-get-children root 'Session)))
                   (key (and session (qso--xml-text session 'Key)))
                   (problem (and session (qso--xml-text session 'Error))))
              (cond
               (key (setq qso--lookup-session key
                          qso--lookup-session-time (float-time))
                    key)
               (problem (message "QSO: QRZ.com: %s" problem) nil)
               (t (message "QSO: QRZ.com did not return a session key") nil))))))))))

(defun qso--lookup-qrz (call)
  "Look CALL up at QRZ.com.  Return an alist of ADIF fields."
  (let ((session (qso--lookup-qrz-session)))
    (when session
      (let ((body (qso--lookup-http-get
                   (format "https://xmldata.qrz.com/xml/current/?s=%s;callsign=%s"
                           (url-hexify-string session)
                           (url-hexify-string call)))))
        (when body
          (let* ((root (qso--lookup-parse-xml body))
                 (entry (car (xml-get-children root 'Callsign)))
                 (session-node (car (xml-get-children root 'Session)))
                 (problem (and session-node (qso--xml-text session-node 'Error))))
            (cond
             (entry
              (let ((first (qso--xml-text entry 'fname))
                    (last (qso--xml-text entry 'name)))
                (qso--lookup-clean
                 (list (cons 'NAME (string-trim (concat (or first "") " " (or last ""))))
                       (cons 'QTH (qso--xml-text entry 'addr2))
                       (cons 'GRIDSQUARE (qso--xml-text entry 'grid))
                       (cons 'STATE (qso--xml-text entry 'state))
                       (cons 'CNTY (qso--xml-text entry 'county))
                       (cons 'COUNTRY (qso--xml-text entry 'country))
                       (cons 'CQZ (qso--xml-text entry 'cqzone))
                       (cons 'ITUZ (qso--xml-text entry 'ituzone))
                       (cons 'LAT (qso--xml-text entry 'lat))
                       (cons 'LON (qso--xml-text entry 'lon))))))
             (t
              (when problem
                (setq qso--lookup-session nil)
                (message "QSO: QRZ.com: %s" problem))
              nil))))))))

;;; Offline country lookup from a cty.dat country file

(defvar qso--cty-prefixes nil
  "Hash of callsign prefix to entity plist, or nil when nothing is loaded.")

(defvar qso--cty-exact nil
  "Hash of whole callsigns to entity plists, from cty.dat \"=\" entries.")

(defvar qso--cty-loaded-file nil
  "The country file currently in memory, as (PATH . MODIFICATION-TIME).")

(defun qso--cty-strip-modifiers (token)
  "Remove cty.dat's per-prefix overrides from TOKEN, leaving the prefix."
  (let ((prefix token))
    (dolist (pattern '("([^)]*)" "\\[[^]]*\\]" "<[^>]*>" "{[^}]*}" "~[^~]*~"))
      (setq prefix (replace-regexp-in-string pattern "" prefix)))
    (string-trim prefix)))

(defun qso--cty-load ()
  "Read `qso-cty-file' into memory.  Return non-nil when usable."
  (let* ((file (and qso-cty-file (expand-file-name qso-cty-file)))
         (stamp (and file (file-readable-p file)
                     (cons file (nth 5 (file-attributes file))))))
    (cond
     ;; Forget which file was loaded as well as its contents, so that a
     ;; country file that reappears later is read again rather than being
     ;; mistaken for the one already in memory.
     ((null stamp)
      (setq qso--cty-prefixes nil qso--cty-exact nil qso--cty-loaded-file nil)
      nil)
     ((equal stamp qso--cty-loaded-file) (and qso--cty-prefixes t))
     (t
      (let ((prefixes (make-hash-table :test 'equal))
            (exact (make-hash-table :test 'equal)))
        (condition-case err
            (with-temp-buffer
              (insert-file-contents file)
              (goto-char (point-min))
              ;; Records are separated by semicolons.  The first line holds
              ;; the entity's details, the rest a comma-separated list of
              ;; the prefixes that belong to it.
              (while (re-search-forward "\\([^;]+\\);" nil t)
                (let* ((record (match-string 1))
                       (lines (split-string record "\n" t))
                       (fields (split-string (or (car lines) "") ":"))
                       (tokens (split-string
                                (mapconcat #'identity (cdr lines) "") "," t)))
                  (when (>= (length fields) 8)
                    (let ((entity (list :country (string-trim (nth 0 fields))
                                        :cqz (string-trim (nth 1 fields))
                                        :ituz (string-trim (nth 2 fields))
                                        :cont (string-trim (nth 3 fields)))))
                      (dolist (token tokens)
                        (let ((entry entity)
                              (bare (qso--cty-strip-modifiers token)))
                          ;; A prefix may override the entity's zones.
                          (when (string-match "(\\([0-9]+\\))" token)
                            (setq entry (plist-put (copy-sequence entry)
                                                   :cqz (match-string 1 token))))
                          (when (string-match "\\[\\([0-9]+\\)\\]" token)
                            (setq entry (plist-put (copy-sequence entry)
                                                   :ituz (match-string 1 token))))
                          (cond
                           ((string-empty-p bare) nil)
                           ;; "=CALL" names one station, not a prefix.
                           ((string-prefix-p "=" bare)
                            (puthash (upcase (substring bare 1)) entry exact))
                           (t (puthash (upcase bare) entry prefixes))))))))))
          (error
           (message "QSO: cannot read country file %s: %s"
                    file (error-message-string err))
           (setq prefixes nil)))
        (if (and prefixes (> (hash-table-count prefixes) 0))
            (progn (setq qso--cty-prefixes prefixes
                         qso--cty-exact exact
                         qso--cty-loaded-file stamp)
                   t)
          (setq qso--cty-prefixes nil qso--cty-exact nil qso--cty-loaded-file nil)
          nil))))))

(defconst qso--cty-plain-suffixes
  '("P" "M" "MM" "AM" "QRP" "A" "B" "LH" "R" "T" "J")
  "Callsign suffixes that say nothing about where a station is.")

(defun qso--cty-base-call (call)
  "Return the part of CALL that decides which entity it belongs to.

This is a rule of thumb rather than a law: a lone digit is an area
within the same country, common suffixes such as /P or /MM are ignored,
and otherwise the shorter part carries the country prefix, as in both
DL/K6SM and K6SM/DL."
  (let ((parts (split-string (upcase call) "/" t)))
    (cond
     ((null parts) (upcase call))
     ((null (cdr parts)) (car parts))
     (t
      (let* ((meaningful (or (seq-remove
                              (lambda (part) (member part qso--cty-plain-suffixes))
                              parts)
                             parts))
             (located (or (seq-remove
                           (lambda (part) (string-match-p "\\`[0-9]\\'" part))
                           meaningful)
                          meaningful)))
        (if (null (cdr located))
            (car located)
          (car (sort (copy-sequence located)
                     (lambda (a b) (< (length a) (length b)))))))))))

(defun qso--cty-lookup (call)
  "Return the entity plist for CALL from the country file, or nil."
  (when (qso--cty-load)
    (let ((whole (upcase (string-trim call))))
      (or (gethash whole qso--cty-exact)
          (let ((base (qso--cty-base-call whole)))
            (or (gethash base qso--cty-exact)
                ;; Longest prefix wins, so K1 beats K.
                (let ((length (length base))
                      (hit nil))
                  (while (and (> length 0) (null hit))
                    (setq hit (gethash (substring base 0 length) qso--cty-prefixes))
                    (setq length (1- length)))
                  hit)))))))

(defun qso--lookup-dxcc (call)
  "Return country and zone fields for CALL from the country file."
  (when qso-call-lookup-dxcc
    (let ((entity (qso--cty-lookup call)))
      (when entity
        (qso--lookup-clean
         (list (cons 'COUNTRY (plist-get entity :country))
               (cons 'CQZ (plist-get entity :cqz))
               (cons 'ITUZ (plist-get entity :ituz))
               (cons 'CONT (plist-get entity :cont))))))))

;;; Putting a lookup together and using the result

(defun qso--lookup-fetch (call)
  "Gather everything known about CALL as an alist of ADIF fields.

The country file supplies a floor that works offline for any callsign;
whatever the chosen source knows is laid over the top of it."
  (let ((offline (qso--lookup-dxcc call))
        (online (pcase qso-call-lookup-source
                  ('callook (qso--lookup-callook call))
                  ('hamqth (qso--lookup-hamqth call))
                  ('qrz (qso--lookup-qrz call))
                  (_ nil)))
        (result '()))
    (dolist (pair (append offline online))
      (setq result (cons pair (assq-delete-all (car pair) result))))
    (nreverse result)))

(define-derived-mode qso-info-mode special-mode "QSO Info"
  "Major mode for the callsign lookup report.

The report is something to read and then dismiss, so the buffer is a
`special-mode' one: it is read-only and \\<qso-info-mode-map>\\[quit-window] buries it.")

(defun qso--lookup-show (call data)
  "Display DATA for CALL in the *Callsign Info* buffer."
  (with-current-buffer (get-buffer-create "*Callsign Info*")
    (qso-info-mode)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (if (null data)
          (insert (format "Nothing found for %s.\n" (upcase call)))
        (insert (format "%s\n\n" (upcase call)))
        (dolist (pair data)
          (insert (format "%-12s %s\n" (symbol-name (car pair)) (cdr pair)))))
      (goto-char (point-min)))
    (display-buffer (current-buffer))))

(defun qso--lookup-autofill (call data)
  "Put DATA for CALL into the form, and keep the rest for the ADIF record.
Return the list of fields that were filled in."
  (setq qso--lookup-call (upcase (string-trim call)))
  (setq qso--lookup-extra nil)
  (let ((filled '())
        (touched nil))
    (dolist (field qso-call-lookup-fields)
      (let ((value (cdr (assq field data))))
        (when value
          (let ((widget (nth 1 (assq field qso--widget-alist))))
            (cond
             ((and widget (qso--widget-accepts-p widget value))
              (widget-value-set widget value)
              (setq touched t)
              (push field filled))
             (widget
              ;; On the form but unable to hold this value, as with a
              ;; menu-choice that does not offer it.
              (message "QSO: %s cannot be set to %S from the form" field value))
             (t
              ;; Not on the form, so carry it to the record instead.
              (push (cons field value) qso--lookup-extra)
              (push field filled)))))))
    (when touched (widget-setup) (qso--fontify-labels))
    (nreverse filled)))

(defun qso--lookup-call-value ()
  "Return the callsign currently typed into the form, or nil."
  (let* ((widget (nth 1 (assq 'CALL qso--widget-alist)))
         (value (and widget (string-trim (or (widget-value widget) "")))))
    (unless (or (null value) (string-empty-p value)) value)))

(defun qso-call-lookup-at-point (&optional autofill)
  "Look up the callsign on the form and show what is known about it.
With AUTOFILL non-nil, also fill in `qso-call-lookup-fields'."
  (interactive "P")
  (let ((call (qso--lookup-call-value)))
    (cond
     ((null call) (message "QSO: no callsign entered"))
     (t
      (message "QSO: looking up %s..." (upcase call))
      (let ((data (qso--lookup-fetch call)))
        (qso--lookup-show call data)
        (cond
         ((null data)
          (message "QSO: nothing found for %s" (upcase call)))
         (autofill
          (let ((filled (qso--lookup-autofill call data)))
            (if filled
                (message "QSO: filled in %s"
                         (mapconcat #'symbol-name filled ", "))
              (message "QSO: nothing to fill in for %s" (upcase call)))))
         (t (message "QSO: %d field(s) found for %s"
                     (length data) (upcase call)))))))))


;;; Appearance and mode

;; These inherit the standard faces `adif.el' gets from font-lock, so a
;; field name looks the same on the form as the matching ADIF tag does in
;; the log file, and both follow whatever theme is loaded.

(defface qso-label '((t :inherit font-lock-keyword-face))
  "Face for field names on the QSO form."
  :group 'qso)

(defface qso-note '((t :inherit font-lock-comment-face))
  "Face for the lines at the top of the form."
  :group 'qso)

(defface qso-value '((t :inherit default))
  "Face for readings taken from the radio."
  :group 'qso)

(defface qso-unit '((t :inherit font-lock-string-face))
  "Face for units and the modes a reading is logged as."
  :group 'qso)

(defface qso-ok '((t :inherit success))
  "Face for a working radio link."
  :group 'qso)

(defface qso-warn '((t :inherit warning))
  "Face for a radio link still being established."
  :group 'qso)

(defface qso-danger '((t :inherit error))
  "Face for a radio link that is down."
  :group 'qso)

(defun qso--face-region (from to face)
  "Give the text between FROM and TO the appearance of FACE.

An overlay is used rather than a text property.  `font-lock-mode' is on
by default in Emacs, and fontifying a region begins by removing the
`face' text properties in it, so a colour put on as a text property
comes off again the moment the form is first displayed.  Overlay faces
font-lock does not touch.

The overlay is marked so that `qso--fontify-labels' can find its own
again, and evaporates if the text it covers is deleted."
  (let ((ov (make-overlay from to)))
    (overlay-put ov 'qso-face-overlay t)
    (overlay-put ov 'face face)
    (overlay-put ov 'evaporate t)
    ;; The same face is put on as a text property as well.  Font-lock
    ;; removes it again wherever it is running, which is what the
    ;; overlay is for; where it is not running, or where something else
    ;; has taken the overlay away, the property is what shows.
    (let ((inhibit-read-only t))
      (add-face-text-property from to face t))
    ov))

(defun qso--fontify-labels ()
  "Colour the field names down the left of the form.

The names are part of each widget's `:format', so they are ordinary
buffer text rather than anything the widget redraws on its own.  They
are coloured again after every redraw, since a widget that is cleared
or refilled reinstates its format and takes the old overlay with it."
  (remove-overlays (point-min) (point-max) 'qso-face-overlay t)
  (save-excursion
    (goto-char (point-min))
    ;; The title line, which names the operator and the log file.
    (qso--face-region (line-beginning-position) (line-end-position) 'qso-note))
  (if qso--widget-alist
      ;; A name is part of its own widget's `:format', so it is looked for
      ;; inside that widget.  Guessing at the shape of the line instead
      ;; misses any field whose format is indented differently, or not at
      ;; all, which is a thing `qso-form-field-definitions' is free to do.
      (dolist (entry qso--widget-alist)
        (let* ((field (nth 0 entry))
               (widget (nth 1 entry))
               (from (widget-get widget :from))
               (to   (widget-get widget :to)))
          (when (and (markerp from) (markerp to)
                     (marker-position from) (marker-position to))
            (save-excursion
              (goto-char from)
              (when (re-search-forward
                     (concat "\\_<" (regexp-quote (symbol-name field)) "\\_>")
                     to t)
                (qso--face-region (match-beginning 0) (match-end 0)
                                  'qso-label))))))
    ;; Before the widgets have been remembered, go by the shape of the
    ;; formats, allowing whatever indent they use.
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*\\([A-Z][A-Z0-9_]*\\)\\_>" nil t)
        (qso--face-region (match-beginning 1) (match-end 1) 'qso-label)))))

(defun qso-activate (pos &optional event)
  "Press the button at POS, or finish entering the field there.

RET does both jobs in a form, and widget.el decides between them by
keeping two keymaps: `widget-keymap', where RET presses a button, and
`widget-field-keymap', where it ends an entry.  Every widget in this
form carries one keymap so that the form's own commands work throughout
it, so the choice is made here, by looking at what is under point,
rather than by which keymap happens to be in force.

Without this, a menu-choice field such as MODE or BAND -- which is a
button, not a field -- inherits the field keymap's RET, which finds no
field, falls through to the global RET, and leaves the value
unchangeable.

EVENT is the input event, as for `widget-button-press'."
  (interactive "@d")
  (if (get-char-property pos 'button)
      (widget-button-press pos event)
    (widget-field-activate pos event)))

(defvar qso-command-map
  (let ((map (make-sparse-keymap)))
    ;; RET is here rather than left to the widget maps so that it means
    ;; the same thing on a field and on a button; see `qso-activate'.
    (define-key map (kbd "RET") #'qso-activate)
    (define-key map (kbd "C-c C-r") #'qso-hamlib-sync-now)
    (define-key map (kbd "C-c C-t") #'qso-hamlib-toggle)
    (define-key map (kbd "C-c C-l") #'qso-call-lookup-at-point)
    ;; Not C-c C-h: Emacs claims C-h after a prefix for its own list of
    ;; bindings, which is what produced a Fundamental mode help buffer.
    (define-key map (kbd "C-c ?") #'qso-show-keys)
    map)
  "The form's own commands.

Kept apart from the maps they are reached through so that there is one
copy of them, shared by the buffer as a whole and by the inside of every
editable field.  See `qso-field-keymap'.")

(defvar qso-form-map (make-composed-keymap qso-command-map widget-keymap)
  "Keymap of the QSO Log Entry form, in force outside the fields.")

(defvar qso-field-keymap
  (make-composed-keymap qso-command-map widget-field-keymap)
  "Keymap in force while point is inside an editable field of the form.

widget.el gives each field an overlay carrying `widget-field-keymap' as
its `local-map', and an overlay's map replaces the buffer's local map
rather than adding to it.  A binding held only in `qso-form-map' is
therefore invisible everywhere the operator actually types: it answers
on a menu-choice field such as MODE, which is a button and has no such
overlay, and nowhere else.  Composing `qso-command-map' in front of
`widget-field-keymap' puts the form's own commands ahead of the field's
editing keys while leaving those keys intact.")

(defun qso--format-with-sample (format field)
  "Return FORMAT with FIELD's name marked as the widget's sample.

widget.el draws whatever lies between %{ and %} in the widget's
`:sample-face', and it puts that back every time the widget redraws
itself.  A menu-choice redraws completely when a value is chosen, taking
with it any colour applied to the buffer afterwards, so the field name
is marked here and the colouring left to widget.el.

A format that says nothing about the field, or that already has a
sample of its own, is returned unchanged."
  (let ((name (symbol-name field)))
    (if (and (stringp format)
             (not (string-match-p "%{" format))
             ;; Matched without the syntax table's help, so that ADDRESS
             ;; is not found inside ADDRESS_INTL.
             (string-match (concat "\\(?:\\`\\|[^A-Za-z0-9_]\\)\\("
                                   (regexp-quote name)
                                   "\\)\\(?:[^A-Za-z0-9_]\\|\\'\\)")
                           format))
        (concat (substring format 0 (match-beginning 1))
                "%{" name "%}"
                (substring format (match-end 1)))
      format)))

(defun qso--definition-args (field definition)
  "Return DEFINITION's arguments for FIELD, its name marked as a sample.

The definition itself is left alone; only a copy is altered, because
`qso-form-field-definitions' is shared by every form."
  (let* ((args (copy-sequence (cdr definition)))
         (cell args))
    ;; Walk the leading plist only.  A menu-choice's item specifications
    ;; follow it and are not keyword and value pairs.
    (while (and cell (keywordp (car cell)) (cdr cell))
      (when (eq (car cell) :format)
        (setcar (cdr cell) (qso--format-with-sample (cadr cell) field)))
      (setq cell (cddr cell)))
    args))

;; Fields whose codes are what an operator looks for in the menu, the
;; description following as a reminder.  Elsewhere the code means little
;; on its own, so the menu shows the description instead.
(defconst qso--choice-code-first '("BAND" "MODE" "SUBMODE")
  "ADIF fields whose menu shows each code ahead of its description.")

(defun qso--choice-tag (field code description)
  "Return the menu text for CODE, one of FIELD's values, and DESCRIPTION."
  (cond ((or (null description) (string-empty-p description)
             (string= description code))
         code)
        ((member field qso--choice-code-first)
         (format "%s (%s)" code description))
        (t description)))

(defun qso--adif-choices (field)
  "Return menu-choice items for the values adif lists for FIELD, a symbol.
Nil when adif treats FIELD as free text."
  (let ((name (upcase (symbol-name field))))
    (mapcar (lambda (pair)
              (list 'item
                    :tag (qso--choice-tag name (car pair) (cdr pair))
                    :value (car pair)))
            (qso--field-values name))))

(defconst qso--field-units
  '((ALTITUDE . "m") (FREQ . " MHz") (FREQ_RX . " MHz")
    (RX_PWR . "W") (TX_PWR . "W"))
  "Units written after a field's entry area on the form.")

(defun qso--field-values (field)
  "Return the (CODE . DESCRIPTION) pairs FIELD, a string, may take, or nil.
Codes adif marks import-only are left out: ADIF allows them in old logs
but not in new ones."
  (seq-remove (lambda (pair) (adif-value-import-only-p field (car pair)))
              (adif-field-values-for field)))

(defun qso--canonical-values (pairs)
  "Put the values in PAIRS that come from adif's lists in adif's own case.

PAIRS holds (FIELD . VALUE) conses of strings, as typed on the form.
Return (PAIRS . NOTES), NOTES being phrases for `qso--confirm-record'
about values missing from the list their field offers.  A value adif
itself finds wrong is left for `adif-record-problems' to describe."
  (let ((notes '()))
    (setq pairs
          (mapcar (lambda (pair)
                    (let* ((field (car pair))
                           (value (cdr pair))
                           (values (qso--field-values field))
                           (known (and values (assoc-string value values t))))
                      (cond (known (cons field (car known)))
                            ((adif-value-import-only-p field value)
                             (push (format "%s %s is for old logs only" field value)
                                   notes)
                             pair)
                            ((and values (not (adif-value-problem field value)))
                             (push (format "%s %s is not in the ADIF list" field value)
                                   notes)
                             pair)
                            (t pair))))
                  pairs))
    (cons pairs (nreverse notes))))

(defun qso--confirm-record (pairs notes)
  "Ask whether to log the record PAIRS if anything about it is questionable.

NOTES are phrases already found by `qso--canonical-values'.  To them are
added whatever `adif-record-problems' finds in PAIRS, and any field in
it that ADIF allows only in old logs.  Declining signals `user-error'."
  (let ((problems
         (append notes
                 (adif-record-problems pairs)
                 (delq nil (mapcar (lambda (pair)
                                     (when (adif-field-import-only-p (car pair))
                                       (format "%s is a field for old logs only"
                                               (car pair))))
                                   pairs)))))
    (when (and problems
               (not (y-or-n-p
                     (format "%s.  Log anyway? "
                             (mapconcat #'identity problems "; ")))))
      (user-error "Submission canceled; the form is unchanged"))))

(defun qso--completion-table (values)
  "Return a completion table offering the codes in VALUES.
VALUES holds (CODE . DESCRIPTION) pairs.  Case is ignored in matching,
and each code is shown with its meaning."
  (lambda (string pred action)
    (if (eq action 'metadata)
        `(metadata
          (annotation-function
           . ,(lambda (code)
                (let ((description (cdr (assoc code values))))
                  (if (and description (not (string= description code)))
                      (concat "  " description)
                    "")))))
      (let ((completion-ignore-case t))
        (complete-with-action action values string pred)))))

(defun qso--field-label (name)
  "Return the start of the form line for the field called NAME."
  (if (< (length name) 13)
      (format "  %-12s " name)
    (format "  %s " name)))

(defun qso--field-definition (field)
  "Return the widget definition that draws FIELD, a symbol, or nil.

An entry in `qso-form-field-definitions' is used as it stands, except
that a menu-choice listing no choices of its own is given the values
adif holds for FIELD.  Any other field is drawn from what adif knows of
it: a menu when adif lists at most `qso-menu-choice-limit' values for
it, and otherwise an entry area `qso-field-widths' wide, completing from
adif's values where it lists any.  OPERATOR has no definition, being
written from `qso-OPERATOR'.  The shared definitions are not altered."
  (let ((definition (alist-get field qso-form-field-definitions))
        (name (upcase (symbol-name field))))
    (cond
     (definition
      (if (and (eq (car definition) 'menu-choice)
               ;; Past the plist there is nothing: no choices were written.
               (let ((cell (cdr definition)))
                 (while (and cell (keywordp (car cell)))
                   (setq cell (cddr cell)))
                 (null cell)))
          (append definition (qso--adif-choices field))
        definition))
     ((string= name "OPERATOR") nil)
     (t
      (let ((values (qso--field-values name))
            (label (qso--field-label name)))
        (if (and values (<= (length values) qso-menu-choice-limit))
            `(menu-choice :tag ,name :format ,(concat label "%[%v%]") :value ""
                          ,@(qso--adif-choices field))
          `(editable-field
            ;; CALL's line goes on to its lookup buttons.
            :format ,(concat label "%v" (alist-get field qso--field-units "")
                             (if (eq field 'CALL) " " "\n"))
            :size ,(or (alist-get field qso-field-widths) qso-field-default-width)
            :value ""
            ,@(when values
                (list :completions (qso--completion-table values))))))))))

(defconst qso--empty-choice '(item :format "%t\n" :tag "-")
  "What a menu-choice field shows before anything has been chosen.

Such a field starts out empty, and an empty value is not one of the
choices, so widget.el would otherwise render it as \"invalid ()\".  The
placeholder is one character wide rather than nothing at all, so that
there is still a button to move onto and press.

The newline matters: a menu-choice's `:format' ends at the value, the
line being finished by whichever child is on display, so a placeholder
without one lets the next field run onto the same line.")

(easy-menu-define qso-form-menu qso-command-map
  "Menu for the QSO log entry form."
  '("QSO"
    ["Look up callsign" qso-call-lookup-at-point :keys "C-c C-l"
     :help "Show what is known about the callsign in the form"]
    ["Look up and autofill" (lambda () (interactive) (qso-call-lookup-at-point t)) :keys "C-u C-c C-l"
     :help "Also fill in the fields chosen in QSO Callsign Lookup Fields"]
    "---"
    ["Read the radio now" qso-hamlib-sync-now :keys "C-c C-r"
     :active qso-hamlib-enable]
    ["Follow the radio" qso-hamlib-toggle :keys "C-c C-t"
     :active qso-hamlib-enable]
    "---"
    ["Keys" qso-show-keys :keys "C-c ?"]
    ["Customize" (lambda () (interactive) (customize-group 'qso))
     :help "Fields on the form, ADIF file, radio and callsign lookup"]))

(defun qso--key-for (command map)
  "Return how COMMAND is reached in MAP, or nil when it is not bound there."
  (let ((keys (where-is-internal command map t)))
    (and keys (key-description keys))))

(defun qso--insert-key-rows (heading rows map)
  "Insert HEADING and then ROWS, each looked up in MAP.

Every row is (COMMAND . DESCRIPTION) and the key column is read from the
keymap rather than written out here, so this list cannot come to
disagree with what the keys actually do.  A command that is not bound is
left out rather than reported wrongly."
  (let ((found (delq nil
                     (mapcar (lambda (row)
                               (let ((key (qso--key-for (car row) map)))
                                 (and key (cons key (cdr row)))))
                             rows))))
    (when found
      (insert "\n" (propertize heading 'face 'bold) "\n")
      (dolist (row found)
        (insert (format "  %-10s %s\n"
                        (propertize (car row) 'face 'qso-label)
                        (cdr row)))))))

(defun qso-show-keys ()
  "Show the keys and buttons available in the QSO log form."
  (interactive)
  (with-current-buffer (get-buffer-create "*QSO Keys*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert (propertize "QSO Log Entry   keys\n" 'face 'qso-note))
      (qso--insert-key-rows
       "Moving about"
       '((widget-forward . "Next field or button")
         (widget-backward . "Previous field or button")
         (widget-button-press . "Press the button at point"))
       qso-form-map)
      (qso--insert-key-rows
       "Commands, which work inside a field as well as between fields"
       '((qso-call-lookup-at-point
          . "Look up the callsign; with C-u also fill the fields")
         (qso-hamlib-sync-now . "Read frequency and mode from the radio now")
         (qso-hamlib-toggle . "Start or stop following the radio")
         (qso-show-keys . "Show this list"))
       qso-form-map)
      (qso--insert-key-rows
       "Inside a field"
       '((widget-field-activate . "Finish entering this field")
         (widget-complete . "Complete the value where the field offers a choice")
         (widget-kill-line . "Kill to the end of the field"))
       qso-field-keymap)
      (qso--insert-key-rows
       "Help"
       '((describe-mode . "Describe the mode in full"))
       (current-global-map))
      (insert "\n" (propertize "Buttons\n" 'face 'bold))
      (dolist (row '(("Lookup" "Show what is known about the callsign")
                     ("Lookup & Autofill" "Also fill in the chosen fields")
                     ("Submit" "Write the QSO to the ADIF file")
                     ("Clear" "Empty the fields without saving")
                     ("Quit" "Close the form")))
        (insert (format "  %-18s %s\n"
                        (propertize (car row) 'face 'qso-label) (cadr row))))
      (goto-char (point-min)))
    (qso-keys-mode)
    (pop-to-buffer (current-buffer))))

(define-derived-mode qso-keys-mode special-mode "QSO Keys"
  "Major mode for the QSO key list.")

(define-derived-mode qso-mode fundamental-mode "QSO"
  "Major mode for the QSO log entry form.

The buffer is a form: one field per line, with buttons under it.  Fields
are ordinary editable text, so the usual editing keys work inside them.

Moving about

  \\<widget-keymap>\\[widget-forward] moves to the next field or button and \\[widget-backward] to the previous one.
  \\<widget-keymap>\\[widget-button-press] presses the button at point.  Inside a field, \\<widget-field-keymap>\\[widget-field-activate] ends the entry
  and \\[widget-complete] completes it where the field offers a choice.

Commands

\\<qso-form-map>  \\[qso-call-lookup-at-point]
      Look up the callsign in the form and report what is known.
      With a prefix argument, also fill in the fields named by
      `qso-call-lookup-fields'.
  \\[qso-hamlib-sync-now]
      Read frequency and mode from the radio at once.
  \\[qso-hamlib-toggle]
      Start or stop following the radio.
  \\[qso-show-keys]
      Show the keys and the buttons in a buffer of their own.

These four work inside a field as well as between fields; see
`qso-field-keymap' for what that takes.

Buttons

  Lookup, Lookup & Autofill  as \\[qso-call-lookup-at-point] above.
  Submit                     write the QSO to `qso-adif-path'.
  Clear                      empty the fields without writing anything.
  Quit                       close the form.

The date, time and operator are added when the QSO is written, and BAND
is worked out from FREQ when BAND is not on the form.

Everything bound outside the fields, in full:

\\{qso-form-map}"
  (setq-local truncate-lines nil)
  ;; The mode carries the form's keys itself, rather than leaving
  ;; `qso-log-form' to install them afterwards.
  (use-local-map qso-form-map))



(defun qso-log-form ()
  "Create a dynamic QSO log form based on `qso-form-fields`."
  (interactive)
  ;; An older adif, found first on the load path or loaded before this
  ;; package, lacks what the form is built from.
  (unless (fboundp 'adif-record-problems)
    (user-error "QSO needs adif 1.0.7 or later; the adif loaded is older (%s)"
                (or (symbol-file 'adif-field-names 'defvar)
                    (locate-library "adif")
                    "location unknown")))
  (switch-to-buffer qso-form-buffer-name)
  (qso-mode)
  (let ((inhibit-read-only t))
    (erase-buffer))
  (remove-overlays)
  ;; One plain line first, saying what this buffer is.  The radio's own
  ;; line follows, matching `ham-rig'.  The keys are on C-c ? and C-h m
  ;; rather than across the top of every form.
  (widget-insert
   (propertize (format "QSO Log Entry   %s   %s\n" qso-OPERATOR qso-adif-path)
               'face 'qso-note))
  (when (and qso-hamlib-enable qso-hamlib-status-line)
    (setq qso--status-start (copy-marker (point) nil))
    (widget-insert (qso--hamlib-status-line) "\n"))
  (widget-insert "\n")
  (let ((widget-alist '()))
    ;; Create widgets for each field and store in widget-alist in the same order
    (dolist (field-info qso-form-fields)
      (let* ((field (car field-info))
             (clear-after-submit (cdr field-info))
             (field-definition (qso--field-definition field)))
        (when field-definition
          ;; These go in ahead of the definition's own arguments: the
          ;; plist has to come before a menu-choice's item specifications,
          ;; which widget.el reads as the widget's children.
          (let* ((type  (car field-definition))
                 ;; Every widget gets the same keymap, whether it is a
                 ;; field or a button.  widget.el hands it to a field as
                 ;; an overlay `local-map', which replaces the buffer's
                 ;; local map, so a binding kept only in `qso-form-map'
                 ;; would be lost wherever the operator types; RET tells
                 ;; a button from a field by itself, in `qso-activate'.
                 (extra (append (list :keymap qso-field-keymap
                                      ;; The colour of the field name,
                                      ;; which widget.el then maintains
                                      ;; across every redraw of the
                                      ;; widget; see `qso--format-with-sample'.
                                      :sample-face 'qso-label)
                                (when (eq type 'menu-choice)
                                  (list :void qso--empty-choice))))
                 (widget (apply #'widget-create type
                                (append extra
                                        (qso--definition-args
                                         field field-definition)))))
            (setq widget-alist (append widget-alist (list (list field widget clear-after-submit))))
	    (when (eq field 'CALL)
	      (when qso-call-lookup
	        (widget-create 'push-button :button-face 'qso-label
	      		 :notify (lambda (&rest _)
	      			   (qso-call-lookup-at-point nil))
	      		 "Lookup"))
	      (when qso-call-lookup-autofill
	        (widget-insert " ")
	        (widget-create 'push-button :button-face 'qso-label
	      		 :notify (lambda (&rest _)
	      			   (qso-call-lookup-at-point t))
	      		 "Lookup & Autofill"))
	      (widget-insert "\n"))))))

    ;; Add submit, clear and quit buttons
    (widget-insert "\n")
    (widget-create 'push-button :button-face 'qso-label
                   :notify (lambda (&rest _)
                             (let ((record '())
                                   (notes '())
                                   (call-value nil)
                                   (date-value "")
                                   (time-value "")
                                   ;; Keep the radio poller out of the form while
                                   ;; the record is being assembled and written.
                                   (qso--hamlib-inhibit t))
                               ;; Collect data from each widget.  Nothing is
                               ;; cleared until the record has been written, so a
                               ;; submission turned back leaves the form as it was.
                               (dolist (field-pair widget-alist)
                                 (let* ((field (nth 0 field-pair))
                                        (widget (nth 1 field-pair))
                                        (value (string-trim (widget-value widget))))
                                   (cond
                                    ;; QSO_DATE and TIME_ON are written once, at the
                                    ;; end, the clock standing in for either left empty.
                                    ((eq field 'QSO_DATE) (setq date-value value))
                                    ((eq field 'TIME_ON) (setq time-value value))
                                    (t
                                     ;; Store the CALL value for duplicate check
                                     (when (eq field 'CALL)
                                       (setq call-value value))
                                     (unless (string-empty-p value)
                                       (push (cons (upcase (symbol-name field)) value)
                                             record))))))
                               (let ((checked (qso--canonical-values (nreverse record))))
                                 (setq record (car checked)
                                       notes (cdr checked)))
                               ;; BAND from FREQ, unless the operator gave one.
                               (unless (assoc "BAND" record)
                                 (let ((band (qso--band-for-freq (cdr (assoc "FREQ" record)))))
                                   (when band
                                     (setq record (append record (list (cons "BAND" band)))))))
                               ;; Record the radio's MODE and SUBMODE even when those fields are
                               ;; not shown on the form.  SUBMODE is only meaningful alongside the
                               ;; MODE it belongs to, so it is added only when the logged MODE is
                               ;; the one the radio reports; if the operator typed a different
                               ;; mode, that choice stands and neither field is touched.
                               (when (and qso-hamlib-enable qso--hamlib-rig-mode)
                                 (let* ((mode-pair (qso--hamlib-adif-mode))
                                        (rig-mode (car mode-pair))
                                        (rig-submode (cdr mode-pair)))
                                   (when (and rig-mode (not (string-empty-p rig-mode)))
                                     (unless (assoc "MODE" record)
                                       (setq record (append record (list (cons "MODE" rig-mode)))))
                                     (when (and rig-submode
                                                (not (string-empty-p rig-submode))
                                                (not (assoc "SUBMODE" record))
                                                (equal (cdr (assoc "MODE" record)) rig-mode))
                                       (setq record (append record
                                                            (list (cons "SUBMODE" rig-submode))))))))
                               ;; Fields found by a callsign lookup that are not on the form.
                               ;; They are tied to the callsign they were fetched for, so details
                               ;; of one station cannot end up in the record of another.
                               (when (and qso--lookup-extra
                                          call-value
                                          (equal (upcase call-value) qso--lookup-call))
                                 (dolist (pair qso--lookup-extra)
                                   (let ((tag (upcase (symbol-name (car pair)))))
                                     (unless (assoc tag record)
                                       (setq record (append record
                                                            (list (cons tag (cdr pair)))))))))
                               ;; The current UTC date and time stand in for empty fields
                               (let ((utc-time (format-time-string "%Y%m%d %H%M%S" nil t)))
                                 (when (string-empty-p date-value)
                                   (setq date-value (substring utc-time 0 8)))
                                 (when (string-empty-p time-value)
                                   (setq time-value (substring utc-time 9 15))))
                               (setq record (append record
                                                    (list (cons "QSO_DATE" date-value)
                                                          (cons "TIME_ON" time-value)
                                                          (cons "OPERATOR" (format "%s" qso-OPERATOR)))))
                               ;; Anything questionable is put to the operator
                               ;; before the log is touched.
                               (qso--confirm-record record notes)
                               ;; If the ADIF file doesn't yet exist, create it with an ADIF header
                               (unless (file-exists-p qso-adif-path)
                                 (with-temp-buffer
                                   (insert (adif-file-header "Emacs-QSO-Logger"
                                                             qso-program-version
                                                             qso-adif-title))
                                   (write-region (point-min) (point-max) qso-adif-path t))
                                 (message "File created, header written to file"))
                               ;; Check for duplicate callsign
                               (when (and qso-call-duplicates
                                          call-value
                                          (not (string-empty-p call-value)))
                                 (let ((pattern (format "<CALL:%d>%s"
                                                        (length call-value)
                                                        (regexp-quote call-value)))
                                       (occur-buf "*Occur*"))
                                   (with-temp-buffer
                                     (insert-file-contents qso-adif-path)
                                     (occur pattern))
                                   (when (get-buffer occur-buf)
                                     (display-buffer occur-buf)
                                     (let ((proceed (y-or-n-p "Duplicate(s) found — proceed anyway? ")))
                                       (kill-buffer occur-buf)
                                       (goto-char (point-min))
                                       (widget-forward 1)
                                       (unless proceed
                                         (user-error "Submission canceled due to duplicate callsign"))))))
                               ;; Append the record to the file
                               (with-temp-buffer
                                 (insert (adif-record-to-string record))
                                 (write-region (point-min) (point-max) qso-adif-path t))
                               ;; Clear the widgets marked for clearing
                               (dolist (field-pair widget-alist)
                                 (when (nth 2 field-pair)
                                   (widget-value-set (nth 1 field-pair) ""))))
			     ;; Clearing a field redraws its widget, and a
			     ;; menu-choice redraws its whole format, name
			     ;; and all, so the names have to be coloured
			     ;; again or the form comes back plain.
			     (qso--fontify-labels)
			     (goto-char (point-min))
			     (widget-forward 1)
			     ;; The looked-up details belong to the contact just logged.
			     (setq qso--lookup-extra nil)
			     (setq qso--lookup-call nil)
			     (message "QSO logged!"))
		   "Submit")
    (widget-insert " ") ;; Add a space between buttons
    (widget-create 'push-button :button-face 'qso-label
                   :notify (lambda (&rest _)
                             (let ((_adif-string "")
				   (_call-value nil)
                                   (_date-value "")
                                   (_time-value "")
				   (qso--hamlib-inhibit t))
                               ;; Collect data from each widget
                               (dolist (field-pair widget-alist)
                                 (let* ((_field (nth 0 field-pair))
                                        (widget (nth 1 field-pair))
                                        (clear-after-submit (nth 2 field-pair))
                                        (_value (widget-value widget)))
                                     (when clear-after-submit
                                       (widget-value-set widget "")))))
			     (setq qso--lookup-extra nil)
			     (setq qso--lookup-call nil)
			     (qso--fontify-labels)
			     (goto-char (point-min))
			     (widget-forward 1))
                   "Clear")
    (widget-insert " ") ;; Add a space between buttons
    (widget-create 'push-button :button-face 'qso-label
                   :notify (lambda (&rest _)
                             (kill-buffer qso-form-buffer-name))
                   "Quit")
    (widget-setup)
    ;; Remember the widgets so that the radio poller, which runs long after
    ;; this function has returned, can reach them.  This comes before the
    ;; names are coloured, because that works from the widgets.
    (setq-local qso--widget-alist widget-alist)
    (qso--fontify-labels)
    (widget-forward 1)
    (setq-local qso--hamlib-written nil)
    (add-hook 'kill-buffer-hook #'qso-hamlib-stop nil t)
    (when qso-hamlib-enable
      (qso-hamlib-start))))
(provide 'qso)
;;; qso.el ends here
