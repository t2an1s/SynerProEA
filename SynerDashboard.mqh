//+------------------------------------------------------------------+
//|  SynerDashboard.mqh  —  Unified heartbeat  +  dashboard          |
//|  2025-06-14  •  Milestone‑3                                       |
//+------------------------------------------------------------------+
#pragma once
#property copyright "Synergy Strategy+"
#property link      "https://github.com/t2an1s/SynerProEA"
#property strict
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Clipboard.mqh>          // MT5 ≥ build‑3980

//====================================================================
// SECTION 1 •  HEARTBEAT STRUCT + WRITER (called by *both* EAs)
//====================================================================
struct SD_HB                     // one‑line CSV layout
{
   datetime ts;
   double   bal, eq, free;
   double   lots_today, pnl_today, pnl_total;
};

static int    _sd_last_sec = -1;
static string _sd_fname    = "SynergyHB.csv";

//-- call once per second from OnTimer()
void SD_HB_Update()
{
   datetime t = TimeCurrent();
   if(TimeSecond(t) == _sd_last_sec) return;       // 1 Hz gate
   _sd_last_sec = TimeSecond(t);

   SD_HB hb;
   hb.ts   = t;
   hb.bal  = AccountInfoDouble(ACCOUNT_BALANCE);
   hb.eq   = AccountInfoDouble(ACCOUNT_EQUITY);
   hb.free = AccountInfoDouble(ACCOUNT_FREEMARGIN);

   // open pos loop
   hb.lots_today = 0;   double floatPNL = 0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk = PositionGetTicket(i);
      if(!PositionSelectByTicket(tk)) continue;
      hb.lots_today += (TimeDayOfYearUTC(
            (datetime)PositionGetInteger(POSITION_TIME)) ==
            TimeDayOfYearUTC(t) ? PositionGetDouble(POSITION_VOLUME) : 0);
      floatPNL     += PositionGetDouble(POSITION_PROFIT);
   }
   // closed deals
   datetime day0 = t - (t%86400);
   double closedToday = 0, closedTot = 0;
   HistorySelect(0, t);
   for(int d=HistoryDealsTotal()-1; d>=0; --d)
   {
      ulong dtk = HistoryDealGetTicket(d);
      double p  = HistoryDealGetDouble(dtk, DEAL_PROFIT);
      datetime dt= (datetime)HistoryDealGetInteger(dtk, DEAL_TIME);
      closedTot   += p;
      if(dt >= day0) closedToday += p;
   }
   hb.pnl_today  = closedToday + floatPNL;
   hb.pnl_total  = closedTot   + floatPNL;

   int h = FileOpen(_sd_fname, FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(h!=INVALID_HANDLE)
   {
      FileWrite(h, hb.ts, hb.bal, hb.eq, hb.free,
                   hb.lots_today, hb.pnl_today, hb.pnl_total);
      FileClose(h);
   }
}

// simple reader
bool SD_HB_Read(const string fn, SD_HB &out)
{
   int h = FileOpen(fn, FILE_READ|FILE_CSV|FILE_ANSI);
   if(h==INVALID_HANDLE) return(false);
   out.ts         = (datetime)FileReadNumber(h);
   out.bal        = FileReadNumber(h);
   out.eq         = FileReadNumber(h);
   out.free       = FileReadNumber(h);
   out.lots_today = FileReadNumber(h);
   out.pnl_today  = FileReadNumber(h);
   out.pnl_total  = FileReadNumber(h);
   FileClose(h);
   return(true);
}

//====================================================================
// SECTION 2 •  DASHBOARD UI CLASS (only instantiated by EA‑1)
//====================================================================
class CSynerDashboard : public CAppDialog
{
private:
   // colours (sampled from your PNG)
   const color CLR_PURPLE = clrIndigo;   // blocks
   const color CLR_LABEL  = clrYellow;   // static labels
   const color CLR_GREEN  = clrSeaGreen;
   const color CLR_AMBER  = clrOrange;
   const color CLR_RED    = clrTomato;

   // geometry
   static const int PAD = 4, ROW = 18, COL1 = 110, COL2 = 90, COL3 = 90;

   // controls
   CArrayObj _rows;
   CLabel    _hdr, _warn;

   // state
   double   _initBalProp = 0, _peakEq = 0, _minEqToday = DBL_MAX;
   datetime _day0 = 0;
   bool     _connected = false;

   // user inputs (set via EA externals)
public:
   double DD_Daily_Limit, DD_Max_Limit, Challenge_Cost;

   // ctor
   CSynerDashboard() : DD_Daily_Limit(1700), DD_Max_Limit(4000),
                       Challenge_Cost(700) {}

   //----------------------------------------------------------------
   bool Create(const long cid,const string nm,const int win,
               const int x,const int y)
   {
      if(!CAppDialog::Create(cid,nm,win,x,y,680,290)) return(false);
      this.ColorBackground(CLR_PURPLE);

      // header
      _hdr.Create(cid,"hdr",win,0,0,680,ROW+2);
      _hdr.Text("STATUS  ● DISCONNECTED");
      _hdr.ColorBackground(CLR_RED);
      _hdr.ColorText(clrWhite); Add(_hdr);

      // warning banner (hidden by default)
      _warn.Create(cid,"warn",win,0,ROW+2,680,ROW);
      _warn.Text("—");
      _warn.ColorBackground(CLR_RED);
      _warn.Visible(false); Add(_warn);

      // table skeleton (static labels)
      AddRow("Volume");               AddRow("Daily PnL");
      AddRow("Summary PnL");          AddRow("Swaps & Com");
      AddRow("Trading Days");         AddSep();
      AddRow("Daily DD");             AddRow("Max DD");
      AddRow("Today Allowed DD");     AddRow("Max Allowed DD");
      AddRow("Balance & Equity");     AddSep();
      AddRow("Loss on Prop");
      AddRow("Profit on Real");
      AddRow("Recovery");

      EventSetTimer(1);
      return(true);
   }
   //----------------------------------------------------------------
   void Destroy()
   {
      EventKillTimer();
      CAppDialog::Destroy();
   }
   //----------------------------------------------------------------
private:
   // mini‑helpers
   void AddRow(const string label)
   {
      int idx=_rows.Total();
      int top=(idx+2)*(ROW+1);
      CreateLabel("lbl"+(string)idx,label,0,top,COL1,CLR_LABEL);
      CreateLabel("v1_"+(string)idx,"—",COL1,top,COL2,CLR_PURPLE);
      CreateLabel("v2_"+(string)idx,"—",COL1+COL2,top,COL2,CLR_PURPLE);
      CreateLabel("rem_"+(string)idx,"—",COL1+COL2*2,top,680-(COL1+COL2*2),CLR_PURPLE);
   }
   void AddSep()
   {
      int top=(2+_rows.Total())*(ROW+1)+2;
      CCanvas *r=new CCanvas;
      r.CreateBitmapLabel(m_chart_id,"sep"+(string)_rows.Total(),m_subwin,
                          0,top,680,2,clrWhite);
      Add(r);
   }
   void CreateLabel(const string name,const string txt,const int x,const int y,
                    const int w,const color bg)
   {
      CLabel *l=new CLabel;
      l.Create(m_chart_id,name,m_subwin,x+PAD,y,w-PAD,ROW);
      l.Text(txt);  l.ColorText(clrWhite); l.ColorBackground(bg);
      l.Tooltip(txt); _rows.Add(l); Add(l);
   }
   //----------------------------------------------------------------
public:
   // MAIN 1 Hz REFRESH  (hook from OnTimer in EA‑1)
   void Tick(const string hbProp="SynergyHB.csv",
             const string hbLive="..\\Live\\SynergyHB.csv")
   {
      SD_HB prop, live;
      bool okProp=SD_HB_Read(hbProp,prop);
      bool okLive=SD_HB_Read(hbLive,live);

      if(!okProp)          { ShowWarn("Prop heartbeat missing"); return; }
      if(TimeCurrent()-prop.ts>5) { ShowWarn("Prop heartbeat stale"); return; }
      _connected=true; _warn.Visible(false);
      _hdr.ColorBackground(CLR_GREEN);
      _hdr.Text("STATUS  ● CONNECTED  |  Working mode: Prop");

      // first‑init
      if(_initBalProp==0) {_initBalProp=prop.bal; _peakEq=prop.eq; }

      // midnight reset
      if(_day0==0) _day0=prop.ts - (prop.ts%86400);
      if(prop.ts-_day0>=86400) { _minEqToday=prop.eq; _day0+=86400; }
      _minEqToday=MathMin(_minEqToday,prop.eq);
      _peakEq    =MathMax(_peakEq,   prop.eq);

      // calc DDs
      double ddDaily   = _minEqToday - _initBalProp;
      double ddMax     = prop.eq     - _peakEq;
      double ddDailyPct= MathAbs(ddDaily)/_initBalProp*100.0;
      double ddMaxPct  = MathAbs(ddMax)/_peakEq*100.0;

      // recovery
      double remainToFail=MathMax(0.0,prop.bal-(_initBalProp-DD_Max_Limit));
      double recDen=Challenge_Cost+remainToFail;
      double recPct=(recDen==0?100:live.pnl_total/recDen*100);
      recPct=MathMin(recPct,100);

      // ---- populate table ----
      SetVal(0,0,DoubleToString(prop.lots_today,2));
      SetVal(0,1,DoubleToString(live.lots_today,2));
      SetVal(1,0,DoubleToString(prop.pnl_today,2));
      SetVal(1,1,DoubleToString(live.pnl_today,2));
      SetVal(2,0,DoubleToString(prop.pnl_total,2)+" / "+DoubleToString(DD_Max_Limit,0));
      SetVal(2,1,DoubleToString(live.pnl_total,2)+" / "+DoubleToString(Challenge_Cost,0));
      // row4 trading days skipped (computed in EA and injected via remarks)
      // DD rows
      SetVal(6,0,StringFormat("%.2f (%.1f%%)",ddDaily,ddDailyPct),
                   ColourFor(ddDailyPct,DD_Daily_Limit/_initBalProp*100));
      SetVal(7,0,StringFormat("%.2f (%.1f%%)",ddMax,ddMaxPct),
                   ColourFor(ddMaxPct,DD_Max_Limit/_initBalProp*100));
      SetVal(8,0,DoubleToString(DD_Daily_Limit,0));
      SetVal(9,0,DoubleToString(DD_Max_Limit,0));
      SetVal(10,0,StringFormat("%.2f / %.2f",prop.bal,prop.eq));
      // cost‑recovery
      SetVal(12,0,DoubleToString(-remainToFail,2));
      SetVal(13,0,DoubleToString(live.pnl_total,2));
      SetVal(14,0,StringFormat("%.1f%%",recPct),
                   ColourFor(recPct,100,true));

      // copy‑to‑clipboard shortcut
      if(ChartGetInteger(0,CHART_EVENT_MOUSE_CLICK)==CHARTEVENT_CLICK)
      {
         if(KeyState(KB_CTRL))
         {
            string t = TableToTSV();
            ClipboardSetText(t);
            Print("SynerDashboard: table copied to clipboard.");
         }
      }
   }
   //----------------------------------------------------------------
private:
   // helpers
   void ShowWarn(const string txt)
   {
      _hdr.ColorBackground(CLR_RED);
      _warn.Text(txt); _warn.Visible(true);
   }
   void SetVal(const int row,const int col,const string txt,
               const color bg=CLR_PURPLE)
   {
      // rows are offset by 2 (hdr + warn), 4 cols per row
      string name = StringFormat("v%d_%d",row,col);
      CLabel *l   = (CLabel*)ObjectGet(name,m_chart_id);
      if(l==NULL) return;
      l.Text(txt);
      l.Tooltip(txt);
      l.ColorBackground(bg);
   }
   color ColourFor(double pct,double limit,bool reverse=false)
   {
      if(reverse)   // bigger = better (recovery)
      {
         if(pct>=100) return(CLR_GREEN);
         if(pct>=80)  return(CLR_AMBER);
         return(CLR_RED);
      }
      else          // bigger = worse (DD)
      {
         if(pct>=limit)      return(CLR_RED);
         if(pct>=limit*0.8)  return(CLR_AMBER);
         return(CLR_GREEN);
      }
   }
   string TableToTSV()
   {
      string out="";
      for(int i=0;i<_rows.Total();i+=4)
      {
         string lbl=((CLabel*)_rows.At(i))->Text();
         string v1 =((CLabel*)_rows.At(i+1))->Text();
         string v2 =((CLabel*)_rows.At(i+2))->Text();
         out+=lbl+"\t"+v1+"\t"+v2+"\r\n";
      }
      return(out);
   }
};
//====================================================================
// END FILE
//====================================================================
