/*
browse_energy.do
Green-Trade Project — Quick browse of energy variables
Run: do dofiles/browse_energy.do
*/

use "data8514_SI/data8514_SI.dta", clear

* ── Electricity ───────────────────────────────────────────────────────────────
br psid year efuvcu eplvcu enpvcu

* ── Fuel — monetary value (vcu) ───────────────────────────────────────────────
br psid year zpovcu zpdvcu zpsvcu zpivcu zpzvcu zpxvcu ///
             znovcu zndvcu znsvcu znivcu znzvcu znxvcu

* ── Fuel — physical quantity (kcu) ───────────────────────────────────────────
br psid year zpokcu zpdkcu zpskcu zpikcu ///
             znokcu zndkcu znskcu znikcu

* ── All energy together ───────────────────────────────────────────────────────
br psid year                                    ///
   efuvcu eplvcu enpvcu                          ///
   zpovcu zpdvcu zpsvcu zpivcu zpzvcu zpxvcu     ///
   znovcu zndvcu znsvcu znivcu znzvcu znxvcu     ///
   zpokcu zpdkcu zpskcu zpikcu                   ///
   znokcu zndkcu znskcu znikcu
