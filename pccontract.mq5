#property copyright "PCCONTRACT"
#property version   "1.04"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- Parâmetros de Entrada
input group "Configurações Gerais"
input ulong  InpMagicNumber = 123456;     // Magic Number
input double InpTargetProfit = 500.0;     // Meta de Lucro Global ($) [0 = Desativar]
input double InpMaxLoss = -200.0;         // Limite de Perda Global ($) [0 = Desativar]

//--- Estrutura do Painel PCCONTRACT
class CPcContractPanel : public CAppDialog
{
private:
   CButton m_btnBuy;      
   CButton m_btnSell;     
   CEdit   m_editLot;     
   
   CLabel  m_lblSL;
   CEdit   m_editSL;
   CLabel  m_lblTP;
   CEdit   m_editTP;
   
   CButton m_btnCloseAll;
   CButton m_btnBreakeven;
   
   CLabel  m_lblTrDist;
   CEdit   m_editTrDist;
   CButton m_btnTrailing;
   
   CLabel  m_lblProfit;
   CLabel  m_lblRisk;

   CTrade  m_trade;       
   bool    m_trailingActive;

public:
   CPcContractPanel() : m_trailingActive(false) {}
   
   virtual bool Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2);
   
   EVENT_MAP_BEGIN(CPcContractPanel)
      ON_EVENT(ON_CLICK, m_btnBuy, OnClickBuy)
      ON_EVENT(ON_CLICK, m_btnSell, OnClickSell)
      ON_EVENT(ON_CLICK, m_btnCloseAll, OnClickCloseAll)
      ON_EVENT(ON_CLICK, m_btnBreakeven, OnClickBreakeven)
      ON_EVENT(ON_CLICK, m_btnTrailing, OnClickTrailing)
   EVENT_MAP_END(CAppDialog)

   void InitTrade();
   void OnClickBuy();
   void OnClickSell();
   void OnClickCloseAll();
   void OnClickBreakeven();
   void OnClickTrailing();
   
   void UpdateProfit();
   void UpdateRisk();
   void CheckGlobalProfit();
   void CheckTrailing();
};

void CPcContractPanel::InitTrade()
{
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   m_trade.SetDeviationInPoints(50);
}

//--- Desenhando a Interface
bool CPcContractPanel::Create(const long chart, const string name, const int subwin, const int x1, const int y1, const int x2, const int y2)
{
   if(!CAppDialog::Create(chart, name, subwin, x1, y1, x2, y2)) return(false);

   // Botão de Venda
   if(!m_btnSell.Create(chart, name+"_Sell", subwin, 20, 40, 110, 100)) return false;
   m_btnSell.Text("SELL");
   m_btnSell.ColorBackground(clrCrimson);
   m_btnSell.Color(clrWhite);
   Add(m_btnSell);

   // Caixa de Lote
   if(!m_editLot.Create(chart, name+"_Lot", subwin, 120, 55, 180, 85)) return false;
   m_editLot.Text("1.0");
   Add(m_editLot);

   // Rótulo de Risco (Abaixo do Lote)
   if(!m_lblRisk.Create(chart, name+"_lblRisk", subwin, 115, 88, 185, 105)) return false;
   m_lblRisk.Text("Risco: 0.00");
   Add(m_lblRisk);

   // Botão de Compra
   if(!m_btnBuy.Create(chart, name+"_Buy", subwin, 190, 40, 280, 100)) return false;
   m_btnBuy.Text("BUY");
   m_btnBuy.ColorBackground(clrForestGreen);
   m_btnBuy.Color(clrWhite);
   Add(m_btnBuy);

   // Rótulo Stop Loss
   if(!m_lblSL.Create(chart, name+"_lblSL", subwin, 20, 110, 140, 125)) return false;
   m_lblSL.Text("Stop Loss (pontos)");
   Add(m_lblSL);

   // Caixa de Stop Loss
   if(!m_editSL.Create(chart, name+"_SL", subwin, 20, 125, 110, 145)) return false;
   m_editSL.Text("1000");
   Add(m_editSL);

   // Rótulo Take Profit
   if(!m_lblTP.Create(chart, name+"_lblTP", subwin, 170, 110, 280, 125)) return false;
   m_lblTP.Text("Take Profit (pontos)");
   Add(m_lblTP);

   // Caixa de Take Profit
   if(!m_editTP.Create(chart, name+"_TP", subwin, 190, 125, 280, 145)) return false;
   m_editTP.Text("2000");
   Add(m_editTP);

   // Botão Fechar Tudo
   if(!m_btnCloseAll.Create(chart, name+"_CloseAll", subwin, 20, 155, 280, 185)) return false;
   m_btnCloseAll.Text("FECHAR TUDO");
   m_btnCloseAll.ColorBackground(clrDarkOrange);
   m_btnCloseAll.Color(clrWhite);
   Add(m_btnCloseAll);

   // Botão Breakeven (Ação Direta)
   if(!m_btnBreakeven.Create(chart, name+"_BE", subwin, 20, 195, 280, 225)) return false;
   m_btnBreakeven.Text("SET BREAKEVEN");
   m_btnBreakeven.ColorBackground(clrDodgerBlue);
   m_btnBreakeven.Color(clrWhite);
   Add(m_btnBreakeven);

   // Trailing Stop Label e Edit
   if(!m_lblTrDist.Create(chart, name+"_lblTr", subwin, 20, 235, 110, 250)) return false;
   m_lblTrDist.Text("Trailing Pts:");
   Add(m_lblTrDist);

   if(!m_editTrDist.Create(chart, name+"_TrDist", subwin, 20, 250, 100, 275)) return false;
   m_editTrDist.Text("1500");
   Add(m_editTrDist);

   // Trailing Toggle Button
   if(!m_btnTrailing.Create(chart, name+"_Trailing", subwin, 115, 240, 280, 275)) return false;
   m_btnTrailing.Text("TRAILING: OFF");
   m_btnTrailing.ColorBackground(clrGray);
   m_btnTrailing.Color(clrWhite);
   Add(m_btnTrailing);

   // Rótulo de Lucro
   if(!m_lblProfit.Create(chart, name+"_lblProfit", subwin, 20, 290, 280, 310)) return false;
   m_lblProfit.Text("Lucro Flutuante: 0.00");
   Add(m_lblProfit);

   return(true);
}

//--- Execução de Ordens
void CPcContractPanel::OnClickBuy()
{
   double lot = StringToDouble(m_editLot.Text());
   double sl_points = StringToDouble(m_editSL.Text());
   double tp_points = StringToDouble(m_editTP.Text());
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   
   double ask = tick.ask;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double sl = (sl_points > 0) ? NormalizeDouble(ask - (sl_points * point), digits) : 0;
   double tp = (tp_points > 0) ? NormalizeDouble(ask + (tp_points * point), digits) : 0;
   
   if(!m_trade.Buy(lot, _Symbol, ask, sl, tp))
      Print("Erro BUY: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
}

void CPcContractPanel::OnClickSell()
{
   double lot = StringToDouble(m_editLot.Text());
   double sl_points = StringToDouble(m_editSL.Text());
   double tp_points = StringToDouble(m_editTP.Text());
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   
   double bid = tick.bid;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   double sl = (sl_points > 0) ? NormalizeDouble(bid + (sl_points * point), digits) : 0;
   double tp = (tp_points > 0) ? NormalizeDouble(bid - (tp_points * point), digits) : 0;
   
   if(!m_trade.Sell(lot, _Symbol, bid, sl, tp))
      Print("Erro SELL: ", m_trade.ResultRetcode(), " - ", m_trade.ResultRetcodeDescription());
}

//--- Fechar Tudo
void CPcContractPanel::OnClickCloseAll()
{
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
            m_trade.PositionClose(pos.Ticket());
      }
   }
}

//--- Botão Set Breakeven (Ação Instantânea)
void CPcContractPanel::OnClickBreakeven()
{
   CPositionInfo pos;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
         {
            double open_price = pos.PriceOpen();
            double sl = pos.StopLoss();
            double tp = pos.TakeProfit();
            long type = pos.PositionType();
            
            double current_price = (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            
            bool modify = false;
            double new_sl = sl;
            
            if(type == POSITION_TYPE_BUY)
            {
               if(current_price > open_price && sl < open_price)
               {
                  new_sl = NormalizeDouble(open_price, digits);
                  modify = true;
               }
            }
            else if(type == POSITION_TYPE_SELL)
            {
               if(current_price < open_price && (sl > open_price || sl == 0))
               {
                  new_sl = NormalizeDouble(open_price, digits);
                  modify = true;
               }
            }
            
            if(modify) m_trade.PositionModify(pos.Ticket(), new_sl, tp);
         }
      }
   }
}

//--- Botão Trailing Toggle
void CPcContractPanel::OnClickTrailing()
{
   m_trailingActive = !m_trailingActive;
   if(m_trailingActive)
   {
      m_btnTrailing.Text("TRAILING: ON");
      m_btnTrailing.ColorBackground(clrSeaGreen);
   }
   else
   {
      m_btnTrailing.Text("TRAILING: OFF");
      m_btnTrailing.ColorBackground(clrGray);
   }
}

//--- Atualizar Lucro Flutuante
void CPcContractPanel::UpdateProfit()
{
   double profit = 0.0;
   CPositionInfo pos;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
            profit += pos.Profit() + pos.Swap() + pos.Commission();
      }
   }
   m_lblProfit.Text("Lucro Flutuante: " + DoubleToString(profit, 2));
}

//--- Atualizar Exibição de Risco Financeiro
void CPcContractPanel::UpdateRisk()
{
   double lot = StringToDouble(m_editLot.Text());
   double sl_points = StringToDouble(m_editSL.Text());
   
   if(lot > 0 && sl_points > 0)
   {
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      
      if(tick_size > 0)
      {
         double price_dist = sl_points * point;
         double risk_money = (price_dist / tick_size) * tick_value * lot;
         
         string currency = AccountInfoString(ACCOUNT_CURRENCY);
         m_lblRisk.Text("Risco: " + DoubleToString(risk_money, 2) + " " + currency);
      }
   }
   else
   {
      m_lblRisk.Text("Risco: 0.00");
   }
}

//--- Checar Meta Global
void CPcContractPanel::CheckGlobalProfit()
{
   double profit = 0.0;
   CPositionInfo pos;
   bool has_positions = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
         {
            profit += pos.Profit() + pos.Swap() + pos.Commission();
            has_positions = true;
         }
      }
   }
   
   if(has_positions)
   {
      if(InpTargetProfit > 0 && profit >= InpTargetProfit)
      {
         Print("Meta atingida!");
         OnClickCloseAll();
      }
      else if(InpMaxLoss < 0 && profit <= InpMaxLoss)
      {
         Print("Stop atingido!");
         OnClickCloseAll();
      }
   }
}

//--- Lógica de Trailing Ativo
void CPcContractPanel::CheckTrailing()
{
   if(!m_trailingActive) return;
   
   double tr_dist_points = StringToDouble(m_editTrDist.Text());
   if(tr_dist_points <= 0) return;
   
   CPositionInfo pos;
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;
   
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   
   int stoplevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int spread = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   int min_dist_points = MathMax(stoplevel, spread * 2);
   if(min_dist_points < 50) min_dist_points = 50;
   double min_dist = min_dist_points * point;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(pos.SelectByIndex(i))
      {
         if(pos.Symbol() == _Symbol && pos.Magic() == InpMagicNumber)
         {
            double sl = pos.StopLoss();
            double tp = pos.TakeProfit();
            long type = pos.PositionType();
            
            double new_sl = sl;
            
            if(type == POSITION_TYPE_BUY)
            {
               double tr_sl = tick.bid - (tr_dist_points * point);
               if(tr_sl > new_sl) new_sl = NormalizeDouble(tr_sl, digits);
               
               if(new_sl > tick.bid - min_dist && new_sl != 0) 
                  new_sl = NormalizeDouble(tick.bid - min_dist, digits);
            }
            else if(type == POSITION_TYPE_SELL)
            {
               double tr_sl = tick.ask + (tr_dist_points * point);
               if(tr_sl < new_sl || new_sl == 0) new_sl = NormalizeDouble(tr_sl, digits);
               
               if(new_sl < tick.ask + min_dist && new_sl != 0) 
                  new_sl = NormalizeDouble(tick.ask + min_dist, digits);
            }
            
            if(new_sl != 0 && MathAbs(new_sl - sl) >= (point * 10.0))
            {
               m_trade.PositionModify(pos.Ticket(), new_sl, tp);
            }
         }
      }
   }
}

//--- Instanciando
CPcContractPanel ExtPanel;

int OnInit()
{
   ExtPanel.InitTrade();
   
   if(!ExtPanel.Create(0, "PCCONTRACT", 0, 50, 50, 350, 380))
      return(INIT_FAILED);
      
   ExtPanel.Run();
   EventSetTimer(1);
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ExtPanel.Destroy(reason);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   ExtPanel.ChartEvent(id, lparam, dparam, sparam);
}

void OnTimer()
{
   ExtPanel.UpdateProfit();
   ExtPanel.UpdateRisk();
}

void OnTick()
{
   ExtPanel.CheckTrailing();
   ExtPanel.CheckGlobalProfit();
}