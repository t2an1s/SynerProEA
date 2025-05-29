#property copyright "t2an1s"
#property link      "https://github.com/t2an1s/SynerProEA"

// SynPropEA1_Dashboard.mqh

// --- Structs ---
struct PivotPoint {
    datetime time;
    double price;
};

// --- Helper struct for combined pivots (for zigzag drawing) ---
struct CombinedPivotVisual { 
    datetime time;
    double price;
    // Explicit default constructor
    CombinedPivotVisual() : time(0), price(0.0) {} 
};


// --- Dashboard Color Constants ---
#define COLOR_BG_YELLOW       C'255,255,204' 
#define COLOR_BG_GREEN        C'204,255,204' 
#define COLOR_BG_ORANGE       C'255,224,204' 
#define COLOR_BG_DARK_PURPLE  C'102,0,102'   
#define COLOR_BG_LIGHT_PURPLE C'230,204,230' 
#define COLOR_BG_GREY         C'211,211,211' 
#define COLOR_TEXT_DARK       clrBlack
#define COLOR_TEXT_WHITE      clrWhite
#define COLOR_TEXT_GREEN      clrGreen
#define COLOR_TEXT_RED        clrRed
#define COLOR_TEXT_BLUE       clrBlue 

// --- Dashboard Layout Constants ---
#define DASH_PREFIX "SynPropDash_"
#define DASH_START_X 10
#define DASH_START_Y 25 

#define COL_LABEL_WIDTH 160      
#define COL_VALUE_WIDTH 180      
#define COL_PROP_ACC_WIDTH 100   
#define COL_REAL_ACC_WIDTH 100   
#define COL_REMARKS_WIDTH 110    

#define ROW_STD_HEIGHT 16        // Changed from 18
#define ROW_HEADER_HEIGHT 18     // Changed from 20
#define TEXT_PADDING 3           // Changed from 5

// --- Static variables to store calculated limits & initial values ---
static double stat_initial_challenge_balance_prop = 0;
static double stat_max_daily_dd_abs_prop = 0;
static double stat_max_acc_dd_abs_prop = 0;
static double stat_stage_target_abs_prop = 0;
static int    stat_min_trading_days_prop_total = 0; 

// --- Object Name Constants (Ensure these match your EA's usage) ---
// Top Info
#define OBJ_TOP_LIC_BG     DASH_PREFIX + "TopLicBg"
#define OBJ_TOP_LIC_LABEL  DASH_PREFIX + "TopLicLabel"
#define OBJ_TOP_LIC_VALUE  DASH_PREFIX + "TopLicValue"
#define OBJ_TOP_WMODE_VALUE DASH_PREFIX + "TopWModeValue"
#define OBJ_TOP_STATUS_VALUE DASH_PREFIX + "TopStatusValue"
#define OBJ_CURRENT_DATETIME_LABEL DASH_PREFIX + "CurrentDateTimeLabel" 
// Live Trading Info Headers
#define OBJ_LIVE_HEADER_BG          DASH_PREFIX + "LiveHeaderBg"
#define OBJ_LIVE_HEADER_TITLE       DASH_PREFIX + "LiveHeaderTitle"
#define OBJ_LIVE_HEADER_PROP        DASH_PREFIX + "LiveHeaderProp"
#define OBJ_LIVE_HEADER_REAL        DASH_PREFIX + "LiveHeaderReal"
#define OBJ_LIVE_HEADER_REMARKS     DASH_PREFIX + "LiveHeaderRemarks"
// Live Trading Info Rows 
#define OBJ_LIVE_VOL_ROWLABEL_TEXT  DASH_PREFIX + "LiveVolRLText"
#define OBJ_LIVE_VOL_PROP_TEXT      DASH_PREFIX + "LiveVolPropText"
#define OBJ_LIVE_VOL_REAL_TEXT      DASH_PREFIX + "LiveVolRealText"
#define OBJ_LIVE_VOL_REM_TEXT       DASH_PREFIX + "LiveVolRemText"  
#define OBJ_LIVE_DPNL_ROWLABEL_TEXT DASH_PREFIX + "LiveDPNLRLText"
#define OBJ_LIVE_DPNL_PROP_TEXT     DASH_PREFIX + "LiveDPNLPropText"
#define OBJ_LIVE_DPNL_REAL_TEXT     DASH_PREFIX + "LiveDPNLRealText"
#define OBJ_LIVE_DPNL_REM_TEXT      DASH_PREFIX + "LiveDPNLRemText"
#define OBJ_LIVE_SPNL_ROWLABEL_TEXT DASH_PREFIX + "LiveSPNLRLText"
#define OBJ_LIVE_SPNL_PROP_TEXT     DASH_PREFIX + "LiveSPNLPropText"
#define OBJ_LIVE_SPNL_REAL_TEXT     DASH_PREFIX + "LiveSPNLRealText"
#define OBJ_LIVE_SPNL_REM_TEXT      DASH_PREFIX + "LiveSPNLRemText"
#define OBJ_LIVE_SWAP_ROWLABEL_TEXT DASH_PREFIX + "LiveSwapRLText"
#define OBJ_LIVE_SWAP_PROP_TEXT     DASH_PREFIX + "LiveSwapPropText"
#define OBJ_LIVE_SWAP_REAL_TEXT     DASH_PREFIX + "LiveSwapRealText"
#define OBJ_LIVE_SWAP_REM_TEXT      DASH_PREFIX + "LiveSwapRemText"
#define OBJ_LIVE_DAYS_ROWLABEL_TEXT DASH_PREFIX + "LiveDaysRLText"
#define OBJ_LIVE_DAYS_PROP_TEXT     DASH_PREFIX + "LiveDaysPropText"
#define OBJ_LIVE_DAYS_REAL_TEXT     DASH_PREFIX + "LiveDaysRealText"
#define OBJ_LIVE_DAYS_REM_TEXT      DASH_PREFIX + "LiveDaysRemText"
// New constants for Swaps & Commission row
#define OBJ_LIVE_COSTS_ROWLABEL_TEXT DASH_PREFIX + "LiveCostsRLText"
#define OBJ_LIVE_COSTS_PROP_TEXT     DASH_PREFIX + "LiveCostsPropText"
#define OBJ_LIVE_COSTS_REAL_TEXT     DASH_PREFIX + "LiveCostsRealText"
#define OBJ_LIVE_COSTS_REM_TEXT      DASH_PREFIX + "LiveCostsRemText"

// Account Status Section Headers
#define OBJ_ACC_STAT_HEADER_BG      DASH_PREFIX + "AccStatHeaderBg"
#define OBJ_ACC_STAT_HEADER_TITLE   DASH_PREFIX + "AccStatHeaderTitle" 
#define OBJ_ACC_STAT_HEADER_PROP    DASH_PREFIX + "AccStatHeaderProp"
#define OBJ_ACC_STAT_HEADER_REAL    DASH_PREFIX + "AccStatHeaderReal"
#define OBJ_ACC_STAT_HEADER_REMARKS DASH_PREFIX + "AccStatHeaderRemarks"
// Account Status - Rows 
#define OBJ_ACC_STAT_ACC_ROWLABEL_TEXT  DASH_PREFIX + "AccStatAccRLText"  // Will be "Account / Currency"
#define OBJ_ACC_STAT_ACC_PROP_TEXT      DASH_PREFIX + "AccStatAccPropText"
#define OBJ_ACC_STAT_ACC_REAL_TEXT      DASH_PREFIX + "AccStatAccRealText"
#define OBJ_ACC_STAT_ACC_REM_TEXT       DASH_PREFIX + "AccStatAccRemText"
#define OBJ_ACC_STAT_BAL_ROWLABEL_TEXT  DASH_PREFIX + "AccStatBalRLText"
#define OBJ_ACC_STAT_BAL_PROP_TEXT      DASH_PREFIX + "AccStatBalPropText"
#define OBJ_ACC_STAT_BAL_REAL_TEXT      DASH_PREFIX + "AccStatBalRealText"
#define OBJ_ACC_STAT_BAL_REM_TEXT       DASH_PREFIX + "AccStatBalRemText"
#define OBJ_ACC_STAT_EQ_ROWLABEL_TEXT   DASH_PREFIX + "AccStatEqRLText"
#define OBJ_ACC_STAT_EQ_PROP_TEXT       DASH_PREFIX + "AccStatEqPropText"
#define OBJ_ACC_STAT_EQ_REAL_TEXT       DASH_PREFIX + "AccStatEqRealText"
#define OBJ_ACC_STAT_EQ_REM_TEXT        DASH_PREFIX + "AccStatEqRemText"
#define OBJ_ACC_STAT_LEV_ROWLABEL_TEXT  DASH_PREFIX + "AccStatLevRLText" // Will be "Leverage / Server"
#define OBJ_ACC_STAT_LEV_PROP_TEXT      DASH_PREFIX + "AccStatLevPropText"
#define OBJ_ACC_STAT_LEV_REAL_TEXT      DASH_PREFIX + "AccStatLevRealText"
#define OBJ_ACC_STAT_LEV_REM_TEXT       DASH_PREFIX + "AccStatLevRemText"
#define OBJ_ACC_STAT_DDD_ROWLABEL_TEXT  DASH_PREFIX + "AccStatDDDRLText"
#define OBJ_ACC_STAT_DDD_PROP_TEXT      DASH_PREFIX + "AccStatDDDPropText"
#define OBJ_ACC_STAT_DDD_REAL_TEXT      DASH_PREFIX + "AccStatDDDRealText"
#define OBJ_ACC_STAT_DDD_REM_TEXT       DASH_PREFIX + "AccStatDDDRemText"
#define OBJ_ACC_STAT_MDD_ROWLABEL_TEXT  DASH_PREFIX + "AccStatMDDRLText"
#define OBJ_ACC_STAT_MDD_PROP_TEXT      DASH_PREFIX + "AccStatMDDPropText"
#define OBJ_ACC_STAT_MDD_REAL_TEXT      DASH_PREFIX + "AccStatMDDRealText"
#define OBJ_ACC_STAT_MDD_REM_TEXT       DASH_PREFIX + "AccStatMDDRemText"
#define OBJ_ACC_STAT_TGT_ROWLABEL_TEXT  DASH_PREFIX + "AccStatTgtRLText"
#define OBJ_ACC_STAT_TGT_PROP_TEXT      DASH_PREFIX + "AccStatTgtPropText"
#define OBJ_ACC_STAT_TGT_REAL_TEXT      DASH_PREFIX + "AccStatTgtRealText"
#define OBJ_ACC_STAT_TGT_REM_TEXT       DASH_PREFIX + "AccStatTgtRemText"
#define OBJ_ACC_STAT_MIND_ROWLABEL_TEXT DASH_PREFIX + "AccStatMinDRLText" 
#define OBJ_ACC_STAT_MIND_PROP_TEXT     DASH_PREFIX + "AccStatMinDPropText"
#define OBJ_ACC_STAT_MIND_REAL_TEXT     DASH_PREFIX + "AccStatMinDRealText"
#define OBJ_ACC_STAT_MIND_REM_TEXT      DASH_PREFIX + "AccStatMinDRemText"
#define OBJ_ACC_STAT_FMAR_ROWLABEL_TEXT DASH_PREFIX + "AccStatFMarRLText"
#define OBJ_ACC_STAT_FMAR_PROP_TEXT     DASH_PREFIX + "AccStatFMarPropText"
#define OBJ_ACC_STAT_FMAR_REAL_TEXT     DASH_PREFIX + "AccStatFMarRealText"
#define OBJ_ACC_STAT_FMAR_REM_TEXT      DASH_PREFIX + "AccStatFMarRemText"

// Cost Recovery Section Headers
#define OBJ_COST_REC_HEADER_BG      DASH_PREFIX + "CostRecHeaderBg"
#define OBJ_COST_REC_HEADER_TITLE   DASH_PREFIX + "CostRecHeaderTitle"
#define OBJ_COST_REC_HEADER_LOSS    DASH_PREFIX + "CostRecHeaderLoss"
#define OBJ_COST_REC_HEADER_PROFIT  DASH_PREFIX + "CostRecHeaderProfit"
#define OBJ_COST_REC_HEADER_REC     DASH_PREFIX + "CostRecHeaderRec"

// Cost Recovery Rows
#define OBJ_COST_REC_DD_ROWLABEL_TEXT  DASH_PREFIX + "CostRecDDRLText"
#define OBJ_COST_REC_DD_LOSS_TEXT      DASH_PREFIX + "CostRecDDLossText"
#define OBJ_COST_REC_DD_PROFIT_TEXT    DASH_PREFIX + "CostRecDDProfitText"
#define OBJ_COST_REC_DD_REC_TEXT       DASH_PREFIX + "CostRecDDRecText"

#define OBJ_COST_REC_MAX_ROWLABEL_TEXT DASH_PREFIX + "CostRecMaxRLText"
#define OBJ_COST_REC_MAX_LOSS_TEXT     DASH_PREFIX + "CostRecMaxLossText"
#define OBJ_COST_REC_MAX_PROFIT_TEXT   DASH_PREFIX + "CostRecMaxProfitText"
#define OBJ_COST_REC_MAX_REC_TEXT      DASH_PREFIX + "CostRecMaxRecText"

// --- Helper Functions ---
void CreateRectangle(long chart_id, string name, int x, int y, int width, int height, color bgColor, int z_order = 0){ ObjectDelete(chart_id, name); if(ObjectCreate(chart_id, name, OBJ_RECTANGLE_LABEL, 0, 0, 0)) { ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x); ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y); ObjectSetInteger(chart_id, name, OBJPROP_XSIZE, width); ObjectSetInteger(chart_id, name, OBJPROP_YSIZE, height); ObjectSetInteger(chart_id, name, OBJPROP_BGCOLOR, bgColor); ObjectSetInteger(chart_id, name, OBJPROP_COLOR, bgColor); ObjectSetInteger(chart_id, name, OBJPROP_BORDER_TYPE, BORDER_FLAT); ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, z_order); ObjectSetInteger(chart_id, name, OBJPROP_BACK, true); } else { Print("!!! Failed to create rectangle: ", name, ". Error: ", GetLastError()); } }
void CreateText(long chart_id, string name, string text, int x_coord, int y_coord, color textColor, int font_size = 9, string font = "Arial", ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER, int z_order = 1, color bgColor = CLR_NONE){ ObjectDelete(chart_id, name); if(ObjectCreate(chart_id, name, OBJ_LABEL, 0, 0, 0)) { ObjectSetString(chart_id, name, OBJPROP_TEXT, text); ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x_coord); ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y_coord); ObjectSetInteger(chart_id, name, OBJPROP_COLOR, textColor); ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, font_size); ObjectSetString(chart_id, name, OBJPROP_FONT, font); ObjectSetInteger(chart_id, name, OBJPROP_ANCHOR, anchor); ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, z_order); if(bgColor != CLR_NONE) { ObjectSetInteger(chart_id, name, OBJPROP_BGCOLOR, bgColor); ObjectSetInteger(chart_id, name, OBJPROP_BACK, false); } else { ObjectSetInteger(chart_id, name, OBJPROP_BACK, true); } } else { Print("!!! Failed to create text label: ", name, ". Error: ", GetLastError()); } }

// --- Dashboard Functions (Copy from your working version) ---
void Dashboard_Init() {
    long current_chart_id = ChartID(); 
    Print("Dashboard_Init: Building skeleton dashboard...");
    int current_y = DASH_START_Y;
    int current_x = DASH_START_X;
    int total_dash_width_top_info = COL_LABEL_WIDTH + COL_VALUE_WIDTH + TEXT_PADDING; 
    int live_trading_total_width = COL_LABEL_WIDTH + COL_PROP_ACC_WIDTH + COL_REAL_ACC_WIDTH + COL_REMARKS_WIDTH + 3*TEXT_PADDING; 
    int acc_status_total_width = live_trading_total_width;
    int dt_x = int(ChartGetInteger(current_chart_id, CHART_WIDTH_IN_PIXELS) - 150 - DASH_START_X); 
    CreateText(current_chart_id, OBJ_CURRENT_DATETIME_LABEL, "YYYY-MM-DD HH:MM:SS", dt_x, DASH_START_Y - ROW_STD_HEIGHT - 2, COLOR_TEXT_DARK, 8, "Arial", ANCHOR_RIGHT); 
    CreateRectangle(current_chart_id, OBJ_TOP_LIC_BG, current_x, current_y, total_dash_width_top_info, ROW_STD_HEIGHT, COLOR_BG_YELLOW); CreateText(current_chart_id, OBJ_TOP_LIC_LABEL, "License / Version", current_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); CreateText(current_chart_id, OBJ_TOP_LIC_VALUE, "...", current_x + COL_LABEL_WIDTH + TEXT_PADDING*2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    CreateRectangle(current_chart_id, DASH_PREFIX + "TopStatusBg", current_x, current_y, total_dash_width_top_info, ROW_STD_HEIGHT, COLOR_BG_GREEN); CreateText(current_chart_id, DASH_PREFIX + "TopStatusLabel", "Status", current_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); CreateText(current_chart_id, OBJ_TOP_STATUS_VALUE, "Initializing...", current_x + COL_LABEL_WIDTH + TEXT_PADDING*2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    CreateRectangle(current_chart_id, DASH_PREFIX + "TopWModeBg", current_x, current_y, total_dash_width_top_info, ROW_STD_HEIGHT, COLOR_BG_ORANGE); CreateText(current_chart_id, DASH_PREFIX + "TopWModeLabel", "Working mode", current_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); CreateText(current_chart_id, OBJ_TOP_WMODE_VALUE, "...", current_x + COL_LABEL_WIDTH + TEXT_PADDING*2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); current_y += ROW_STD_HEIGHT + TEXT_PADDING; 
    current_x = DASH_START_X; 
    CreateRectangle(current_chart_id, OBJ_LIVE_HEADER_BG, current_x, current_y, live_trading_total_width, ROW_HEADER_HEIGHT, COLOR_BG_DARK_PURPLE); 
    int cell_x = current_x; 
    CreateText(current_chart_id, OBJ_LIVE_HEADER_TITLE, "Live Trading Information", cell_x + COL_LABEL_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_WHITE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; 
    CreateText(current_chart_id, OBJ_LIVE_HEADER_PROP, "Prop Account", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_WHITE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; 
    CreateText(current_chart_id, OBJ_LIVE_HEADER_REAL, "Real Account", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_WHITE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; 
    CreateText(current_chart_id, OBJ_LIVE_HEADER_REMARKS, "Remarks", cell_x + COL_REMARKS_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_WHITE, 9, "Arial", ANCHOR_CENTER); current_y += ROW_HEADER_HEIGHT;
    int live_info_row_label_fontsize = 8;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveVolRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_VOL_ROWLABEL_TEXT, "Volume", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize, "Arial", ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveVolPropBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_VOL_PROP_TEXT, "0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveVolRealBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_VOL_REAL_TEXT, "0.00", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveVolRemBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_VOL_REM_TEXT, "...", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDPNLRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DPNL_ROWLABEL_TEXT, "Daily PnL (Prop/Real)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDPNLPropBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DPNL_PROP_TEXT, "0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_BLUE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDPNLRealBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DPNL_REAL_TEXT, "0.00", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_BLUE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDPNLRemBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DPNL_REM_TEXT, "...", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSPNLRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SPNL_ROWLABEL_TEXT, "Summary PnL (Prop/Real)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSPNLPropBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SPNL_PROP_TEXT, "0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_BLUE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSPNLRealBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SPNL_REAL_TEXT, "0.00", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_BLUE, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSPNLRemBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SPNL_REM_TEXT, "...", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSwapRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SWAP_ROWLABEL_TEXT, "Swaps (Prop/Real)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSwapPropBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SWAP_PROP_TEXT, "0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSwapRealBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SWAP_REAL_TEXT, "0.00", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveSwapRemBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_SWAP_REM_TEXT, "...", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveCostsRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_COSTS_ROWLABEL_TEXT, "Swaps & Comm (P/R)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveCostsPropBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_COSTS_PROP_TEXT, "0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveCostsRealBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_COSTS_REAL_TEXT, "N/A", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveCostsRemBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_COSTS_REM_TEXT, "...", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDaysRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DAYS_ROWLABEL_TEXT, "Trading Days (Prop/Real)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDaysPropBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DAYS_PROP_TEXT, "0/0", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDaysRealBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DAYS_REAL_TEXT, "0/0", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"LiveDaysRemBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_LIVE_DAYS_REM_TEXT, "...", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, live_info_row_label_fontsize,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    current_y += TEXT_PADDING; 
    current_x = DASH_START_X; 
    CreateRectangle(current_chart_id, OBJ_ACC_STAT_HEADER_BG, current_x, current_y, acc_status_total_width, ROW_HEADER_HEIGHT, COLOR_BG_GREY);
    cell_x = current_x; 
    CreateText(current_chart_id, OBJ_ACC_STAT_HEADER_TITLE, "Account Status", cell_x + COL_LABEL_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; 
    CreateText(current_chart_id, OBJ_ACC_STAT_HEADER_PROP, "Prop Account", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; 
    CreateText(current_chart_id, OBJ_ACC_STAT_HEADER_REAL, "Real Account", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; 
    CreateText(current_chart_id, OBJ_ACC_STAT_HEADER_REMARKS, "Remarks", cell_x + COL_REMARKS_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER); current_y += ROW_HEADER_HEIGHT;
    int acc_info_row_label_fontsize = 8; 
    string placeholder_val = "..."; string placeholder_num = "0.00"; string placeholder_dd = placeholder_num + " / " + placeholder_num; string placeholder_days = "0/0";
    string placeholder_target_pnl = "0.00 / 0.00";
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Acc_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_ACC_ROWLABEL_TEXT, "Account / Currency", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Acc_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_ACC_PROP_TEXT, placeholder_val, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Acc_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_ACC_REAL_TEXT, placeholder_val, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Acc_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_ACC_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Bal_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_BAL_ROWLABEL_TEXT, "Balance", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Bal_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_BAL_PROP_TEXT, placeholder_num, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Bal_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_BAL_REAL_TEXT, placeholder_num, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Bal_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_BAL_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Eq_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_EQ_ROWLABEL_TEXT, "Equity", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Eq_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_EQ_PROP_TEXT, placeholder_num, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Eq_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_EQ_REAL_TEXT, placeholder_num, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Eq_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_EQ_REM_TEXT, "+0.00", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_FMar_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_FMAR_ROWLABEL_TEXT, "Free Margin", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_FMar_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_FMAR_PROP_TEXT, placeholder_num, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_FMar_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_FMAR_REAL_TEXT, "N/A", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_FMar_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_FMAR_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Lev_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_LEV_ROWLABEL_TEXT, "Leverage / Server", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Lev_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_LEV_PROP_TEXT, "1:... @ ...", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Lev_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_LEV_REAL_TEXT, "1:... @ ...", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Lev_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_LEV_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_DDD_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_DDD_ROWLABEL_TEXT, "Daily DD ($ Limit / Rem)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_DDD_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_DDD_PROP_TEXT, placeholder_dd, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 8,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_DDD_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_DDD_REAL_TEXT, placeholder_dd, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 8,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_DDD_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_DDD_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MDD_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MDD_ROWLABEL_TEXT, "Max Acc DD ($ Limit / Rem)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MDD_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MDD_PROP_TEXT, placeholder_dd, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 8,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MDD_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MDD_REAL_TEXT, placeholder_dd, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 8,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MDD_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MDD_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Tgt_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_TGT_ROWLABEL_TEXT, "Stage Target ($ Abs / Rem)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Tgt_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_TGT_PROP_TEXT, placeholder_target_pnl, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 8,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Tgt_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_TGT_REAL_TEXT, placeholder_target_pnl, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 8,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_Tgt_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_TGT_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    cell_x = current_x; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MinD_LBLBG", cell_x,current_y,COL_LABEL_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MIND_ROWLABEL_TEXT, "Min Days (Current/Total)", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize,"Arial",ANCHOR_LEFT); cell_x += COL_LABEL_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MinD_PropBG", cell_x,current_y,COL_PROP_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MIND_PROP_TEXT, placeholder_days, cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MinD_RealBG", cell_x,current_y,COL_REAL_ACC_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MIND_REAL_TEXT, placeholder_days, cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_CENTER); cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING; CreateRectangle(current_chart_id, DASH_PREFIX+"AS_MinD_RemBG", cell_x,current_y,COL_REMARKS_WIDTH,ROW_STD_HEIGHT,COLOR_BG_LIGHT_PURPLE); CreateText(current_chart_id, OBJ_ACC_STAT_MIND_REM_TEXT, placeholder_val, cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9,"Arial",ANCHOR_LEFT); current_y += ROW_STD_HEIGHT;
    current_y += TEXT_PADDING; 
    
    // After Account Status section, add Cost Recovery section
    current_y += TEXT_PADDING;
    current_x = DASH_START_X;
    
    // Cost Recovery Header
    CreateRectangle(current_chart_id, OBJ_COST_REC_HEADER_BG, current_x, current_y, acc_status_total_width, ROW_HEADER_HEIGHT, COLOR_BG_YELLOW);
    cell_x = current_x;
    CreateText(current_chart_id, OBJ_COST_REC_HEADER_TITLE, "Cost Recovery Estimate", cell_x + COL_LABEL_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateText(current_chart_id, OBJ_COST_REC_HEADER_LOSS, "Loss on Prop", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING;
    CreateText(current_chart_id, OBJ_COST_REC_HEADER_PROFIT, "Profit on Real", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING;
    CreateText(current_chart_id, OBJ_COST_REC_HEADER_REC, "Recovery", cell_x + COL_REMARKS_WIDTH/2, current_y + ROW_HEADER_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_CENTER);
    current_y += ROW_HEADER_HEIGHT;

    // Daily DD Row
    cell_x = current_x;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecDDRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_DD_ROWLABEL_TEXT, "Daily DD", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize, "Arial", ANCHOR_LEFT);
    cell_x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecDDLossBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_DD_LOSS_TEXT, "-0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_RED, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecDDProfitBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_DD_PROFIT_TEXT, "0.00", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecDDRecBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_DD_REC_TEXT, "0.0 %", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT);
    current_y += ROW_STD_HEIGHT;

    // Max DD Row
    cell_x = current_x;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecMaxRLBg", cell_x, current_y, COL_LABEL_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_MAX_ROWLABEL_TEXT, "Max DD", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, acc_info_row_label_fontsize, "Arial", ANCHOR_LEFT);
    cell_x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecMaxLossBg", cell_x, current_y, COL_PROP_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_MAX_LOSS_TEXT, "-0.00", cell_x + COL_PROP_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_RED, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_PROP_ACC_WIDTH + TEXT_PADDING;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecMaxProfitBg", cell_x, current_y, COL_REAL_ACC_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_MAX_PROFIT_TEXT, "0.00", cell_x + COL_REAL_ACC_WIDTH/2, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_CENTER);
    cell_x += COL_REAL_ACC_WIDTH + TEXT_PADDING;
    CreateRectangle(current_chart_id, DASH_PREFIX+"CostRecMaxRecBg", cell_x, current_y, COL_REMARKS_WIDTH, ROW_STD_HEIGHT, COLOR_BG_LIGHT_PURPLE);
    CreateText(current_chart_id, OBJ_COST_REC_MAX_REC_TEXT, "0.0 %", cell_x + TEXT_PADDING, current_y + ROW_STD_HEIGHT/2, COLOR_TEXT_DARK, 9, "Arial", ANCHOR_LEFT);
    current_y += ROW_STD_HEIGHT;
    
    ChartRedraw(current_chart_id);
    Print("Dashboard_Init: Account Status section completed.");
}
void Dashboard_Deinit() { ObjectsDeleteAll(ChartID(), DASH_PREFIX); ChartRedraw(ChartID()); }
void Dashboard_UpdateStaticInfo(string ea_version, int magic_number, double initial_challenge_balance_prop, 
                                double daily_dd_limit_dollars_from_input,
                                double max_account_dd_dollars_from_input,
                                double stage_target_pct_prop, int min_trading_days_prop, 
                                string symbol = "", string timeframe = "", double challenge_cost = 0 ) {
    long chart_id = ChartID(); 
    ObjectSetString(chart_id, OBJ_TOP_LIC_VALUE, OBJPROP_TEXT, "TESTER / " + ea_version); 
    ObjectSetString(chart_id, OBJ_TOP_WMODE_VALUE, OBJPROP_TEXT, "Prop (Auto)");
    ObjectSetString(chart_id, OBJ_CURRENT_DATETIME_LABEL, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_DATE|TIME_SECONDS) + " Server"); 
    stat_initial_challenge_balance_prop = initial_challenge_balance_prop; 
    stat_min_trading_days_prop_total = min_trading_days_prop; 
    string acc_prop_str = StringFormat("%d (%s)", (int)AccountInfoInteger(ACCOUNT_LOGIN), AccountInfoString(ACCOUNT_CURRENCY));
    ObjectSetString(chart_id, OBJ_ACC_STAT_ACC_PROP_TEXT, OBJPROP_TEXT, acc_prop_str);
    string lev_serv_prop_str = "1:" + IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)) + " @ " + AccountInfoString(ACCOUNT_SERVER);
    ObjectSetString(chart_id, OBJ_ACC_STAT_LEV_PROP_TEXT, OBJPROP_TEXT, lev_serv_prop_str);
    ObjectSetString(chart_id, OBJ_ACC_STAT_MIND_PROP_TEXT, OBJPROP_TEXT, "0/" + IntegerToString(stat_min_trading_days_prop_total)); 
    
    // Correctly assign dollar limits from inputs
    stat_max_daily_dd_abs_prop = daily_dd_limit_dollars_from_input; 
    stat_max_acc_dd_abs_prop = max_account_dd_dollars_from_input;  
    
    double profit_target_abs = initial_challenge_balance_prop * stage_target_pct_prop / 100.0;
    stat_stage_target_abs_prop = profit_target_abs; 

    // Initialize new fields
    ObjectSetString(chart_id, OBJ_LIVE_COSTS_PROP_TEXT, OBJPROP_TEXT, "0.00");
    ObjectSetString(chart_id, OBJ_LIVE_COSTS_REAL_TEXT, OBJPROP_TEXT, "N/A");
    ObjectSetString(chart_id, OBJ_ACC_STAT_FMAR_PROP_TEXT, OBJPROP_TEXT, "0.00");
    ObjectSetString(chart_id, OBJ_ACC_STAT_FMAR_REAL_TEXT, OBJPROP_TEXT, "N/A");

    ObjectSetString(chart_id, OBJ_ACC_STAT_DDD_PROP_TEXT, OBJPROP_TEXT, StringFormat("%.2f / ...", stat_max_daily_dd_abs_prop));
    ObjectSetString(chart_id, OBJ_ACC_STAT_MDD_PROP_TEXT, OBJPROP_TEXT, StringFormat("%.2f / ...", stat_max_acc_dd_abs_prop));
    ObjectSetString(chart_id, OBJ_ACC_STAT_TGT_PROP_TEXT, OBJPROP_TEXT, StringFormat("... / %.2f", stat_stage_target_abs_prop));
    ObjectSetString(chart_id, OBJ_ACC_STAT_ACC_REAL_TEXT, OBJPROP_TEXT, "N/A (N/A)"); // Placeholder for combined
    ObjectSetString(chart_id, OBJ_ACC_STAT_LEV_REAL_TEXT, OBJPROP_TEXT, "N/A @ N/A"); // Placeholder for combined
    ObjectSetString(chart_id, OBJ_ACC_STAT_DDD_REAL_TEXT, OBJPROP_TEXT, "0.00 / 0.00");
    ObjectSetString(chart_id, OBJ_ACC_STAT_MDD_REAL_TEXT, OBJPROP_TEXT, "0.00 / 0.00");
    ObjectSetString(chart_id, OBJ_ACC_STAT_TGT_REAL_TEXT, OBJPROP_TEXT, "0.00 / 0.00");
    ObjectSetString(chart_id, OBJ_ACC_STAT_MIND_REAL_TEXT, OBJPROP_TEXT, "0/0");
    ChartRedraw(chart_id);
}
void Dashboard_UpdateDynamicInfo(
    double prop_balance, double prop_equity, 
    double prop_balance_at_day_start, double prop_peak_equity, int prop_current_trading_days,
    bool session_active,
    double master_ea_volume, 
    double daily_dd_equity_floor_prop, 
    double daily_dd_limit_dollars_prop, 
    double static_max_dd_equity_floor_prop, // Not used in example, but available
    double trailing_max_dd_equity_floor_prop,
    double max_dd_limit_dollars_prop, 
    // New parameters based on guide
    double prop_realized_daily_pnl,
    double prop_floating_pnl,
    double prop_daily_costs,
    double prop_free_margin
    // Slave data is now handled by Dashboard_UpdateSlaveStatus
)
{
    long chart_id = ChartID(); 
    
    // --- Live Trading Info --- 
    // Master EA (Prop) Volume
    ObjectSetString(chart_id, OBJ_LIVE_VOL_PROP_TEXT, OBJPROP_TEXT, DoubleToString(master_ea_volume,2));
 
    // Prop Daily PNL
    double pnl_prop_daily_total = prop_realized_daily_pnl + prop_floating_pnl;
    color pnl_prop_color = (pnl_prop_daily_total >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED; 
    ObjectSetString(chart_id, OBJ_LIVE_DPNL_PROP_TEXT, OBJPROP_TEXT, DoubleToString(pnl_prop_daily_total,2)); 
    ObjectSetInteger(chart_id, OBJ_LIVE_DPNL_PROP_TEXT, OBJPROP_COLOR, pnl_prop_color);
 
    // Summary PNL (Prop)
    double current_summary_pnl_prop = prop_balance - stat_initial_challenge_balance_prop; // From initial balance, using current BALANCE
    color summary_pnl_prop_color = (current_summary_pnl_prop >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    string summary_pnl_prop_str = StringFormat("%.2f / %.2f", current_summary_pnl_prop, stat_stage_target_abs_prop);
    ObjectSetString(chart_id, OBJ_LIVE_SPNL_PROP_TEXT, OBJPROP_TEXT, summary_pnl_prop_str);
    ObjectSetInteger(chart_id, OBJ_LIVE_SPNL_PROP_TEXT, OBJPROP_COLOR, summary_pnl_prop_color);
 
    // Swaps & Commission (Prop)
    ObjectSetString(chart_id, OBJ_LIVE_COSTS_PROP_TEXT, OBJPROP_TEXT, DoubleToString(prop_daily_costs,2));
 
    // Trading Days (Prop)
    ObjectSetString(chart_id, OBJ_LIVE_DAYS_PROP_TEXT, OBJPROP_TEXT, IntegerToString(prop_current_trading_days) + "/" + IntegerToString(stat_min_trading_days_prop_total));
    // Remove the OBJ_ACC_STAT_MIND_PROP_TEXT as it's a duplicate of OBJ_LIVE_DAYS_PROP_TEXT
    ObjectSetString(chart_id, OBJ_ACC_STAT_MIND_ROWLABEL_TEXT, OBJPROP_TEXT, "DEPRECATED"); // Mark old label
    ObjectSetString(chart_id, OBJ_ACC_STAT_MIND_PROP_TEXT, OBJPROP_TEXT, "N/A");
    ObjectSetString(chart_id, OBJ_ACC_STAT_MIND_REAL_TEXT, OBJPROP_TEXT, "N/A");
    ObjectSetString(chart_id, OBJ_ACC_STAT_MIND_REM_TEXT, OBJPROP_TEXT, "Moved to Live Info");


    // --- Account Status Section (Prop) ---
    ObjectSetString(chart_id, OBJ_ACC_STAT_BAL_PROP_TEXT, OBJPROP_TEXT, DoubleToString(prop_balance,2));
    ObjectSetString(chart_id, OBJ_ACC_STAT_EQ_PROP_TEXT, OBJPROP_TEXT, DoubleToString(prop_equity,2));
    ObjectSetString(chart_id, OBJ_ACC_STAT_EQ_REM_TEXT, OBJPROP_TEXT, "+0.00");

    // Free Margin (Prop)
    ObjectSetString(chart_id, OBJ_ACC_STAT_FMAR_PROP_TEXT, OBJPROP_TEXT, DoubleToString(prop_free_margin,2));
 
    // Daily DD (Prop)
    double remaining_daily_dd_prop = prop_equity - daily_dd_equity_floor_prop;
    ObjectSetString(chart_id, OBJ_ACC_STAT_DDD_PROP_TEXT, OBJPROP_TEXT, StringFormat("%.2f / %.2f", daily_dd_limit_dollars_prop, remaining_daily_dd_prop));
    ObjectSetInteger(chart_id, OBJ_ACC_STAT_DDD_PROP_TEXT, OBJPROP_COLOR, (remaining_daily_dd_prop >=0 ? COLOR_TEXT_DARK : COLOR_TEXT_RED));

    // Max DD (Prop) - Assuming Trailing from Peak Equity for "Remaining"
    double remaining_max_dd_prop = prop_equity - trailing_max_dd_equity_floor_prop;
    ObjectSetString(chart_id, OBJ_ACC_STAT_MDD_PROP_TEXT, OBJPROP_TEXT, StringFormat("%.2f / %.2f", max_dd_limit_dollars_prop, remaining_max_dd_prop));
    ObjectSetInteger(chart_id, OBJ_ACC_STAT_MDD_PROP_TEXT, OBJPROP_COLOR, (remaining_max_dd_prop >=0 ? COLOR_TEXT_DARK : COLOR_TEXT_RED));

    // Stage Target (Prop)
    double profit_made_prop = prop_equity - stat_initial_challenge_balance_prop; // Profit from initial challenge balance
    double remaining_to_target_prop = stat_stage_target_abs_prop - profit_made_prop;
    ObjectSetString(chart_id, OBJ_ACC_STAT_TGT_PROP_TEXT, OBJPROP_TEXT, StringFormat("%.2f / %.2f", stat_stage_target_abs_prop, remaining_to_target_prop));
    ObjectSetInteger(chart_id, OBJ_ACC_STAT_TGT_PROP_TEXT, OBJPROP_COLOR, (remaining_to_target_prop > 0 ? COLOR_TEXT_DARK : COLOR_TEXT_GREEN));

    ObjectSetString(chart_id, OBJ_CURRENT_DATETIME_LABEL, OBJPROP_TEXT, TimeToString(TimeTradeServer(), TIME_DATE|TIME_SECONDS) + " Server"); 
    ChartRedraw(chart_id);
}
void Dashboard_UpdateStatus(string status_text, bool is_signal_active) {
    long chart_id = ChartID();
     if (ObjectFind(chart_id, OBJ_TOP_STATUS_VALUE) != -1) { 
        ObjectSetString(chart_id, OBJ_TOP_STATUS_VALUE, OBJPROP_TEXT, status_text);
        if(StringFind(status_text, "LONG")!=-1 && is_signal_active) 
            ObjectSetInteger(chart_id, OBJ_TOP_STATUS_VALUE, OBJPROP_COLOR, COLOR_TEXT_GREEN);
        else if(StringFind(status_text, "SHORT")!=-1 && is_signal_active) 
            ObjectSetInteger(chart_id, OBJ_TOP_STATUS_VALUE, OBJPROP_COLOR, COLOR_TEXT_RED);
        else 
            ObjectSetInteger(chart_id, OBJ_TOP_STATUS_VALUE, OBJPROP_COLOR, COLOR_TEXT_DARK); 
    }
    ChartRedraw(chart_id);
}
void Dashboard_UpdateSlaveStatus( 
    bool is_slave_connected,
    string status_from_slave_file,
    long actual_slave_acc_num,
    string actual_slave_curr,
    double actual_slave_balance,
    double actual_slave_equity,
    double actual_slave_daily_pnl,
    double actual_slave_volume,
    int actual_slave_lev,
    string actual_slave_srv
    )
{
    long chart_id = ChartID();

    // --- Live Trading Info (Slave/Real) ---
    ObjectSetString(chart_id, OBJ_LIVE_VOL_REAL_TEXT, OBJPROP_TEXT, is_slave_connected ? DoubleToString(actual_slave_volume,2) : "N/A");
    
    color pnl_slave_color = (actual_slave_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    ObjectSetString(chart_id, OBJ_LIVE_DPNL_REAL_TEXT, OBJPROP_TEXT, is_slave_connected ? DoubleToString(actual_slave_daily_pnl,2) : "N/A"); 
    ObjectSetInteger(chart_id, OBJ_LIVE_DPNL_REAL_TEXT, OBJPROP_COLOR, pnl_slave_color);

    // Summary PNL (Slave) - This would be slave_equity - slave_initial_balance. We don't have slave_initial_balance from EA2 yet.
    // For now, let's show N/A or just current PNL if that is what is expected.
    // Assuming slave_daily_pnl is the main PNL to show for the slave for now.
    ObjectSetString(chart_id, OBJ_LIVE_SPNL_REAL_TEXT, OBJPROP_TEXT, is_slave_connected ? DoubleToString(actual_slave_daily_pnl,2) : "N/A"); // Or calculate full summary if initial balance is passed
    ObjectSetInteger(chart_id, OBJ_LIVE_SPNL_REAL_TEXT, OBJPROP_COLOR, pnl_slave_color);

    // Trading Days (Slave) - Slave doesn't track this, show N/A
    ObjectSetString(chart_id, OBJ_LIVE_DAYS_REAL_TEXT, OBJPROP_TEXT, "N/A");

    // --- Account Status Section (Slave/Real) ---
    string acc_curr_real_str = "N/A";
    if(is_slave_connected) acc_curr_real_str = IntegerToString(actual_slave_acc_num) + " (" + actual_slave_curr + ")";
    ObjectSetString(chart_id, OBJ_ACC_STAT_ACC_REAL_TEXT, OBJPROP_TEXT, acc_curr_real_str);

    ObjectSetString(chart_id, OBJ_ACC_STAT_BAL_REAL_TEXT, OBJPROP_TEXT, is_slave_connected ? DoubleToString(actual_slave_balance,2) : "N/A"); 
    ObjectSetString(chart_id, OBJ_ACC_STAT_EQ_REAL_TEXT, OBJPROP_TEXT, is_slave_connected ? DoubleToString(actual_slave_equity,2) : "N/A"); 

    string lev_serv_real_str = "N/A";
    if(is_slave_connected) lev_serv_real_str = "1:" + IntegerToString(actual_slave_lev) + " @ " + actual_slave_srv;
    ObjectSetString(chart_id, OBJ_ACC_STAT_LEV_REAL_TEXT, OBJPROP_TEXT, lev_serv_real_str);

    // DD and Target for slave are not typically tracked by master, show N/A
    ObjectSetString(chart_id, OBJ_ACC_STAT_DDD_REAL_TEXT, OBJPROP_TEXT, "N/A");
    ObjectSetString(chart_id, OBJ_ACC_STAT_MDD_REAL_TEXT, OBJPROP_TEXT, "N/A");
    ObjectSetString(chart_id, OBJ_ACC_STAT_TGT_REAL_TEXT, OBJPROP_TEXT, "N/A");

    // Remarks for Slave connection
    if (is_slave_connected) {
        ObjectSetString(chart_id, OBJ_LIVE_VOL_REM_TEXT, OBJPROP_TEXT, "Slave Conn.");
        ObjectSetString(chart_id, OBJ_LIVE_DPNL_REM_TEXT, OBJPROP_TEXT, status_from_slave_file);
    } else {
        ObjectSetString(chart_id, OBJ_LIVE_VOL_REM_TEXT, OBJPROP_TEXT, "Slave N/A");
        ObjectSetString(chart_id, OBJ_LIVE_DPNL_REM_TEXT, OBJPROP_TEXT, status_from_slave_file); // Show last known or error status
    }

    ChartRedraw(chart_id);
}

// --- Chart Visuals Functions ---
void ChartVisuals_InitPivots(bool show_visuals, color up_color, color down_color)
  {
   if(!show_visuals) ChartVisuals_DeinitPivots(); 
   Print("ChartVisuals_InitPivots called. Show: ", show_visuals);
  }

void ChartVisuals_DeinitPivots() // Modified to clear both types of lines
  {
   ObjectsDeleteAll(ChartID(), DASH_PREFIX + "PivotZigZagHigh_", 0, -1);
   ObjectsDeleteAll(ChartID(), DASH_PREFIX + "PivotZigZagLow_", 0, -1);
   ChartRedraw(ChartID());
   Print("ChartVisuals_DeinitPivots called.");
  }

void ChartVisuals_UpdatePivots(const PivotPoint &pivots_h_const[], const PivotPoint &pivots_l_const[], bool show_visuals, color color_low_pivot_lines, color color_high_pivot_lines)
  {
   long chart_id = ChartID();
   // Clear previous lines for highs and lows separately
   ObjectsDeleteAll(chart_id, DASH_PREFIX + "PivotZigZagHigh_", 0, -1); 
   ObjectsDeleteAll(chart_id, DASH_PREFIX + "PivotZigZagLow_", 0, -1); 

   if(!show_visuals) 
     {
      ChartRedraw(chart_id);
      return;
     }
     
   // --- Process and Draw High Pivots ---
   int total_pivots_h = ArraySize(pivots_h_const);
   if (total_pivots_h > 0) 
     {
      PivotPoint pivots_h[]; // Local sortable copy
      if(ArrayResize(pivots_h, total_pivots_h) < 0) { Print("Failed to resize pivots_h copy"); return; }
      ArrayCopy(pivots_h, pivots_h_const);

      // Filter out invalid pivots (time == 0) and count valid ones
      int valid_h_count = 0;
      for(int i=0; i < total_pivots_h; i++) {
          if(pivots_h[i].time != 0) {
              if(valid_h_count != i) pivots_h[valid_h_count] = pivots_h[i]; // Compact the array
              valid_h_count++;
          }
      }
      if(valid_h_count < total_pivots_h && valid_h_count > 0) ArrayResize(pivots_h, valid_h_count);
      else if (valid_h_count == 0) total_pivots_h = 0; // No valid pivots
      
      total_pivots_h = valid_h_count; // Update count to valid pivots

      if(total_pivots_h >= 2)
        {
         // Manual Bubble Sort for pivots_h by time
         bool swapped_h;
         for (int i = 0; i < total_pivots_h - 1; i++) {
             swapped_h = false;
             for (int j = 0; j < total_pivots_h - i - 1; j++) {
                 if (pivots_h[j].time > pivots_h[j+1].time) {
                     PivotPoint temp_h = pivots_h[j];
                     pivots_h[j] = pivots_h[j+1];
                     pivots_h[j+1] = temp_h;
                     swapped_h = true;
                 }
             }
             if (!swapped_h) break;
         }

         // Draw lines for high pivots
         for(int i = 0; i < total_pivots_h - 1; i++)
           {
            string line_name = DASH_PREFIX + "PivotZigZagHigh_" + IntegerToString(i);
            datetime time1 = pivots_h[i].time;
            double price1 = pivots_h[i].price;
            datetime time2 = pivots_h[i+1].time;
            double price2 = pivots_h[i+1].price;

            if(ObjectCreate(chart_id, line_name, OBJ_TREND, 0, time1, price1, time2, price2)) 
              {
               ObjectSetInteger(chart_id, line_name, OBJPROP_COLOR, color_high_pivot_lines); // Use dedicated color
               ObjectSetInteger(chart_id, line_name, OBJPROP_STYLE, STYLE_SOLID);
               ObjectSetInteger(chart_id, line_name, OBJPROP_WIDTH, 1);
               ObjectSetInteger(chart_id, line_name, OBJPROP_RAY_RIGHT, false); 
               ObjectSetInteger(chart_id, line_name, OBJPROP_BACK, false); 
              }
            else { Print("Failed to create pivot high line: ", line_name, " Error: ", GetLastError());}
           }
        }
     }

   // --- Process and Draw Low Pivots ---
   int total_pivots_l = ArraySize(pivots_l_const);
    if(total_pivots_l > 0)
      {
       PivotPoint pivots_l[]; // Local sortable copy
       if(ArrayResize(pivots_l, total_pivots_l) < 0) { Print("Failed to resize pivots_l copy"); return; }
       ArrayCopy(pivots_l, pivots_l_const);

      // Filter out invalid pivots (time == 0) and count valid ones
      int valid_l_count = 0;
      for(int i=0; i < total_pivots_l; i++) {
          if(pivots_l[i].time != 0) {
              if(valid_l_count != i) pivots_l[valid_l_count] = pivots_l[i]; // Compact
              valid_l_count++;
          }
      }
      if(valid_l_count < total_pivots_l && valid_l_count > 0) ArrayResize(pivots_l, valid_l_count);
      else if (valid_l_count == 0) total_pivots_l = 0;

      total_pivots_l = valid_l_count; // Update count

       if(total_pivots_l >= 2)
         {
          // Manual Bubble Sort for pivots_l by time
          bool swapped_l;
          for (int i = 0; i < total_pivots_l - 1; i++) {
              swapped_l = false;
              for (int j = 0; j < total_pivots_l - i - 1; j++) {
                  if (pivots_l[j].time > pivots_l[j+1].time) {
                      PivotPoint temp_l = pivots_l[j];
                      pivots_l[j] = pivots_l[j+1];
                      pivots_l[j+1] = temp_l;
                      swapped_l = true;
                  }
              }
              if (!swapped_l) break;
          }

          // Draw lines for low pivots
          for(int i = 0; i < total_pivots_l - 1; i++)
            {
             string line_name = DASH_PREFIX + "PivotZigZagLow_" + IntegerToString(i);
             datetime time1 = pivots_l[i].time;
             double price1 = pivots_l[i].price;
             datetime time2 = pivots_l[i+1].time;
             double price2 = pivots_l[i+1].price;

             if(ObjectCreate(chart_id, line_name, OBJ_TREND, 0, time1, price1, time2, price2)) 
               {
                ObjectSetInteger(chart_id, line_name, OBJPROP_COLOR, color_low_pivot_lines); // Use dedicated color
                ObjectSetInteger(chart_id, line_name, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(chart_id, line_name, OBJPROP_WIDTH, 1);
                ObjectSetInteger(chart_id, line_name, OBJPROP_RAY_RIGHT, false); 
                ObjectSetInteger(chart_id, line_name, OBJPROP_BACK, false); 
               }
            else { Print("Failed to create pivot low line: ", line_name, " Error: ", GetLastError());}
            }
         }
      }
   ChartRedraw(chart_id);
  }

void ChartVisuals_InitMarketBias(bool show_visuals, color up_color, color down_color) { /* Placeholder */ } 
void ChartVisuals_DeinitMarketBias() { string pf=DASH_PREFIX+"MarketBias"; ObjectsDeleteAll(ChartID(),pf,0,-1); ChartRedraw(ChartID());} 
void ChartVisuals_UpdateMarketBias(double v, bool s) { /* Placeholder */ }

//+------------------------------------------------------------------+
//| Update Cost Recovery Info                                          |
//+------------------------------------------------------------------+
void Dashboard_UpdateCostRecoveryInfo(
    double prop_daily_dd_loss,
    double real_daily_profit,
    double prop_max_dd_loss,
    double real_total_profit,
    double challenge_cost,
    double max_dd_limit
) {
    long chart_id = ChartID();
    
    // Update Daily DD row
    ObjectSetString(chart_id, OBJ_COST_REC_DD_LOSS_TEXT, OBJPROP_TEXT, DoubleToString(prop_daily_dd_loss, 2));
    ObjectSetString(chart_id, OBJ_COST_REC_DD_PROFIT_TEXT, OBJPROP_TEXT, DoubleToString(real_daily_profit, 2));
    
    // Calculate and update Daily DD Recovery %
    double daily_recovery_pct = 0.0;
    if(prop_daily_dd_loss > 0) {
        daily_recovery_pct = (real_daily_profit / prop_daily_dd_loss) * 100.0;
    }
    ObjectSetString(chart_id, OBJ_COST_REC_DD_REC_TEXT, OBJPROP_TEXT, DoubleToString(daily_recovery_pct, 1) + " %");
    
    // Update Max DD row
    ObjectSetString(chart_id, OBJ_COST_REC_MAX_LOSS_TEXT, OBJPROP_TEXT, DoubleToString(prop_max_dd_loss, 2));
    ObjectSetString(chart_id, OBJ_COST_REC_MAX_PROFIT_TEXT, OBJPROP_TEXT, DoubleToString(real_total_profit, 2));
    
    // Calculate and update Max DD Recovery %
    double max_recovery_pct = 0.0;
    if(prop_max_dd_loss > 0) {
        max_recovery_pct = (real_total_profit / prop_max_dd_loss) * 100.0;
    }
    ObjectSetString(chart_id, OBJ_COST_REC_MAX_REC_TEXT, OBJPROP_TEXT, DoubleToString(max_recovery_pct, 1) + " %");
    
    ChartRedraw(chart_id);
}
