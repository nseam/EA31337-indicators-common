//+------------------------------------------------------------------+
//|                                               EA31337 indicators |
//|                                 Copyright 2016-2021, EA31337 Ltd |
//|                                        https://ea31337.github.io |
//+------------------------------------------------------------------+

/*
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * @file
 * Implements Moving Averages Convergence/Divergence indicator.
 */

// Defines.
#define INDI_FULL_NAME "Moving Averages Convergence/Divergence"
#define INDI_SHORT_NAME "MACD"

// Indicator properties.
#property copyright "2016-2021, EA31337 Ltd"
#property link "https://ea31337.github.io"
#property description INDI_FULL_NAME
//--
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots 2
#property indicator_type1 DRAW_HISTOGRAM
#property indicator_type2 DRAW_LINE
#property indicator_color1 Silver
#property indicator_color2 Red
#property indicator_width1 2
#property indicator_width2 1
#property indicator_label1 INDI_SHORT_NAME
#property indicator_label2 "Signal"

// Includes.
#include <EA31337-classes/Indicators/Indi_MACD.mqh>

// Input parameters.
input int InpMACDFastEMA = 12;                              // Fast EMA Period
input int InpMACDSlowEMA = 26;                              // Slow EMA Period
input int InpMACDSignalSMA = 9;                             // Signal SMA Period
input ENUM_APPLIED_PRICE InpMACDAppliedPrice = PRICE_CLOSE; // Applied price
input int InpShift = 0;                                     // Shift
input ENUM_IDATA_SOURCE_TYPE InpSourceType = IDATA_BUILTIN; // Source type

// Global indicator buffers.
double ExtMACDBuffer[];
double ExtSignalBuffer[];

// Global variables.
Indi_MACD *indi;

/**
 * Init event handler function.
 */
void OnInit() {
  // Initialize indicator buffers.
  SetIndexBuffer(0, ExtMACDBuffer, INDICATOR_DATA);
  SetIndexBuffer(1, ExtSignalBuffer, INDICATOR_DATA);
  // Initialize indicator.
  IndiMACDParams _indi_params(::InpMACDFastEMA, ::InpMACDSlowEMA,
                              ::InpMACDSignalSMA, ::InpMACDAppliedPrice,
                              ::InpShift);
  _indi_params.SetDataSourceType(InpSourceType);
  indi = new Indi_MACD(_indi_params);
  // Name for labels.
  // @todo: Use serialized string of _indi_params.
  string short_name =
      StringFormat("%s(%d,%d,%d)", indi.GetName(), ::InpMACDFastEMA,
                   ::InpMACDSlowEMA, ::InpMACDSignalSMA);
  PlotIndexSetString(0, PLOT_LABEL, short_name);
  IndicatorSetString(INDICATOR_SHORTNAME, short_name);
  // Sets first bar from what index will be drawn
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpMACDSignalSMA - 1);
  // Sets indicator shift.
  PlotIndexSetInteger(0, PLOT_SHIFT, InpShift);
  // Drawing settings (MQL4).
  SetIndexStyle(0, DRAW_HISTOGRAM);
  SetIndexStyle(1, DRAW_LINE);
}

/**
 * Calculate event handler function.
 */
int OnCalculate(const int rates_total, const int prev_calculated,
                const datetime &time[], const double &open[],
                const double &high[], const double &low[],
                const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
  int i, start;
  if (rates_total <
      fmax4(0, ::InpMACDFastEMA, ::InpMACDSlowEMA, ::InpMACDSignalSMA)) {
    return (0);
  }
  // Initialize calculations.
  start = prev_calculated == 0
              ? fmax4(0, ::InpMACDFastEMA, ::InpMACDSlowEMA, ::InpMACDSignalSMA)
              : prev_calculated - 1;
  // Main calculations.
  for (i = start; i < rates_total && !IsStopped(); i++) {
    IndicatorDataEntry _entry = indi[i];
    // double _value = indi[i][0];
    bool _is_ready = indi.Get<bool>(
        STRUCT_ENUM(IndicatorState, INDICATOR_STATE_PROP_IS_READY));
    ExtMACDBuffer[i] = _is_ready ? _entry[(int)LINE_MAIN] : 0.0;
    ExtSignalBuffer[i] = _is_ready ? _entry[(int)LINE_SIGNAL] : 0.0;
  }
  // Returns new prev_calculated.
  return (rates_total);
}

/**
 * Deinit event handler function.
 */
void OnDeinit(const int reason) { delete indi; }