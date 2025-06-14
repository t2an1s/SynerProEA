//+------------------------------------------------------------------+
//| SynergyHeartbeat.mqh  — writes one CSV line per second           |
//+------------------------------------------------------------------+
#property strict
struct SHB                         // heartbeat record
  {
   datetime  ts;                   // UTC timestamp
   double    bal, eq, free;        // account metrics
   double    lots_today;           // Σ lots opened since UTC‑00:00
   double    pnl_today;            // closed+floating PnL since UTC‑00:00
   double    pnl_total;            // net PnL since inception
  };

input string   HB_FileName = "SynergyHB.csv";
static  int    lastSec     = -1;
static  SHB    hb;
//--------------------------------------------------------------------
void HB_Update()
  {
   datetime t = TimeCurrent();                 // broker‑UTC sync
   if(TimeSecond(t)==lastSec) return;          // 1 Hz gate
   lastSec = TimeSecond(t);

   //——core metrics
   hb.ts   = t;
   hb.bal  = AccountInfoDouble(ACCOUNT_BALANCE);
   hb.eq   = AccountInfoDouble(ACCOUNT_EQUITY);
   hb.free = AccountInfoDouble(ACCOUNT_FREEMARGIN);

   //——walk open positions once → Σ lots & floating PnL
   double floatPNL=0, lotsToday=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      ENUM_POSITION_TYPE side = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double lots  = PositionGetDouble(POSITION_VOLUME);
      double profit= PositionGetDouble(POSITION_PROFIT);
      datetime oTime=(datetime)PositionGetInteger(POSITION_TIME);
      if(TimeDayOfYearUTC(oTime)==TimeDayOfYearUTC(t))
         lotsToday+=lots;                   // opened today?
      floatPNL+=profit;
     }

   //——history pass for closed PnL today
   datetime dayStart = t - (t%86400);        // UTC 00:00
   double closedPnLToday=0, closedPnLTotal=0;
   HistorySelect(0, t);                      // all deals
   for(int d=HistoryDealsTotal()-1; d>=0; --d)
     {
      ulong  dTicket = HistoryDealGetTicket(d);
      double profit  = HistoryDealGetDouble(dTicket, DEAL_PROFIT);
      datetime dTime = (datetime)HistoryDealGetInteger(dTicket, DEAL_TIME);
      closedPnLTotal += profit;
      if(dTime>=dayStart) closedPnLToday += profit;
     }

   hb.lots_today = lotsToday;
   hb.pnl_today  = closedPnLToday + floatPNL;
   hb.pnl_total  = closedPnLTotal + floatPNL;

   //——flush to CSV (1‑line, overwrite)
   int h = FileOpen(HB_FileName, FILE_WRITE|FILE_CSV|FILE_ANSI);
   if(h!=INVALID_HANDLE)
     {
      FileWrite(h, hb.ts, hb.bal, hb.eq, hb.free,
                   hb.lots_today, hb.pnl_today, hb.pnl_total);
      FileClose(h);
     }
  }
