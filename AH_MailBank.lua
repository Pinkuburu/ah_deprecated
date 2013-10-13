------------------------------------------------------
-- #ģ�������ʼ��ֿ�ģ��
-- #ģ��˵������ǿ�ʼ�����
------------------------------------------------------

AH_MailBank = {
	tItemCache = {},
	szDataPath = "\\Interface\\AH\\data\\mail.AH",
	szCurRole = nil,
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_MailBank.ini"
local bMailHooked = false
local bBagHooked = false

function AH_MailBank.Init(frame)
	local handle = frame:Lookup("", "")
	local hBg = handle:Lookup("Handle_Bg")
	local hBox = handle:Lookup("Handle_Box")
	hBg:Clear()
	hBox:Clear()
	local nIndex = 0
	for i = 1, 7, 1 do
		for j = 1, 14, 1 do
			hBg:AppendItemFromString("<image>w=52 h=52 path=\"ui/Image/LootPanel/LootPanel.UITex\" frame=13 </image>")
			local img = hBg:Lookup(nIndex)
			hBox:AppendItemFromString("<box>w=48 h=48 eventid=524607 </box>")
			local box = hBox:Lookup(nIndex)
			box.nIndex = nIndex
			box.bItemBox = true
			local x, y = (j - 1) * 52, (i - 1) * 52
			img:SetRelPos(x, y)
			box:SetRelPos(x + 2, y + 2)
			box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
			box:SetOverTextFontScheme(0, 15)

			nIndex = nIndex + 1
		end
	end
	hBg:FormatAllItemPos()
	hBox:FormatAllItemPos()

	frame:Lookup("Btn_Prev"):Hide()
	frame:Lookup("Btn_Next"):Hide()
end

function AH_MailBank.LoadMailData(frame, szName)
	local handle = frame:Lookup("", "")
	local hBox = handle:Lookup("Handle_Box")
	--���ԭ������
	for i = 0, 97, 1 do
		local box = hBox:Lookup(i)
		box:ClearObject()
		box:ClearObjectIcon()
	end

	--���¸�������
	local tItemCache = AH_MailBank.tItemCache[szName]
	local i = 0
	for k, v in pairs(tItemCache) do
		local item = GetItem(v[1])
		local box = hBox:Lookup(i)
		box.nUiId = k
		box.data = v
		box:SetObject(UI_OBJECT_ITEM_ONLY_ID, k, v[1], v[2], v[3], v[4])
		box:SetObjectIcon(Table_GetItemIconID(k))
		UpdateItemBoxExtend(box, item)
		if v[5] > 1 then
			box:SetOverText(0, v[5])
		else
			box:SetOverText(0, "")
		end
		i = i + 1
	end
	frame:Lookup("", ""):Lookup("Text_Account"):SetText(szName)
end

function AH_MailBank.DeleteEmptyMail(frame)
	local frame = frame or Station.Lookup("Normal/MailPanel")
    local handle = frame:Lookup("PageSet_Total/Page_Receive"):Lookup("", "")
    local hList = handle:Lookup("Handle_MailList")
    local MailClient = GetMailClient()
	local tMail = MailClient.GetMailList("all") or {}
	local bDelte = false
	for _, dwID in ipairs(tMail) do
	     local mail = MailClient.GetMailInfo(dwID)
	     if mail and not mail.bItemFlag and not mail.bMoneyFlag  and mail.GetText() == "" then
	        MailClient.DeleteMail(dwID)
	     end
	end
end

function AH_MailBank.SaveItemCache()
	local MailClient = GetMailClient()
	local tMail = MailClient.GetMailList("all") or {}
	local t, count, ids = {}, {}, {}
	for _, dwID in ipairs(tMail) do
		local tItem = AH_MailBank.GetMailItem(dwID)
		for k, v in pairs(tItem) do
			if not count[k] then
				count[k]= 0
			end
			if not ids[k] then
				ids[k] = {dwID}
			else
				table.insert(ids[k], dwID)
			end
			if not t[k] then
				count[k] = v[5]
				t[k] = {v[1], v[2], v[3], v[4], v[5], ids[k]}
			else
				count[k] = count[k] + v[5]
				t[k] = {v[1], v[2], v[3], v[4], count[k], ids[k]}
			end
		end
	end
	return t
end


function AH_MailBank.GetMailItem(dwID)
	local t, count = {}, {}
	local mail = GetMailClient().GetMailInfo(dwID)
	if mail.bItemFlag then
		for i = 0, 7, 1 do
			local item = mail.GetItem(i)
			if item then
				if not count[item.nUiId] then
					count[item.nUiId] = 0	--������ͬ����Ʒ������
				end
				if not t[item.nUiId] then
					count[item.nUiId] = item.nStackNum
					t[item.nUiId] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, item.nStackNum}
				else
					count[item.nUiId] = count[item.nUiId] + item.nStackNum
					t[item.nUiId] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, count[item.nUiId]}
				end
			end
		end
	end
	return t
	--if mail.bMoneyFlag and mail.nMoney ~= 0 then
	--end
end

function AH_MailBank.OnUpdate()
	local frame = Station.Lookup("Normal/MailPanel")
	if frame and frame:IsVisible() then
		if not bMailHooked then
			local page = frame:Lookup("PageSet_Total/Page_Receive")
			local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
			if not page:Lookup("Btn_MailBank") then
				local hBtnMailBank = temp:Lookup("Btn_MailBank")
				if hBtnMailBank then
					hBtnMailBank:ChangeRelation(page, true, true)
					hBtnMailBank:SetRelPos(600, 8)
					hBtnMailBank.OnLButtonClick = function()
						AH_MailBank.OpenPanel()
					end
				end
			end
			Wnd.CloseWindow(temp)
			bMailHooked = true
		end
		local MailClient = GetMailClient()
		local tMail = MailClient.GetMailList("all") or {}
		for _, dwID in ipairs(tMail) do
			local mail = MailClient.GetMailInfo(dwID)
			local target = Station.Lookup("Normal/Target")
			if target then
				mail.RequestContent(target.dwID)
			end
		end
		local szName = GetClientPlayer().szName
		AH_MailBank.tItemCache[szName] = AH_MailBank.SaveItemCache()
	elseif not frame or not frame:IsVisible() then
		bMailHooked = false
	end

	local frame = Station.Lookup("Normal/BigBagPanel")
	if not bBagHooked and frame and frame:IsVisible() then
		local temp = Wnd.OpenWindow("interface\\AH\\AH_Widget.ini")
		if not frame:Lookup("Btn_Mail") then
			local hBtnMail = temp:Lookup("Btn_Mail")
			if hBtnMail then
				hBtnMail:ChangeRelation(frame, true, true)
				hBtnMail:SetRelPos(55, 0)
				hBtnMail.OnLButtonClick = function()
					AH_MailBank.OpenPanel()
				end
				hBtnMail.OnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = GetFormatText("�ʼ��ֿ�", 163) .. GetFormatText("\n����������Դ������ʼ��ֿ⡣", 162)
					OutputTip(szTip, 400, {x, y, w, h})
				end
				hBtnMail.OnMouseLeave = function()
					HideTip()
				end
			end
		end
		Wnd.CloseWindow(temp)
		bBagHooked = true
	elseif not frame or not frame:IsVisible() then
		bBagHooked = false
	end
end

function AH_MailBank.FormatItemLeftTime(nTime)
	--nTime = (nTime - GetTime())/1000
	if nTime >= 86400 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_DAY, math.floor(nTime / 86400))
	elseif nTime >= 3600 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_HOURE, math.floor(nTime / 3600))
	elseif nTime >= 60 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_MINUTE, math.floor(nTime / 60))
	else
		return g_tStrings.STR_MAIL_LEFT_LESS_ONE_M
	end
end
------------------------------------------------------------
-- �ص�����
------------------------------------------------------------
function AH_MailBank.OnFrameCreate()
	this:RegisterEvent("GET_MAIL_CONTENT")
end

function AH_MailBank.OnEvent(event)
	if event == "GET_MAIL_CONTENT" then
	end
end

function AH_MailBank.OnEditChanged()
end

function AH_MailBank.OnLButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Btn_Close" then
		AH_MailBank.ClosePanel()
	elseif szName == "Btn_Account" then
		local hText = frame:Lookup("", ""):Lookup("Text_Account")
		local x, y = hText:GetAbsPos()
		local w, h = hText:GetSize()
		local menu = {}
		menu.nMiniWidth = w + 20
		menu.x = x
		menu.y = y + h
		for k, v in pairs(AH_MailBank.tItemCache) do
			local m = {
				szOption = k,
				fnAction = function()
					AH_MailBank.szCurRole = k
					AH_MailBank.Init(frame)
					AH_MailBank.LoadMailData(frame, k)
				end
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	end
end

function AH_MailBank.OnItemLButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local data = this.data
		local item = GetItem(data[1])
		if item then
			local MailClient = GetMailClient()
			for k, v in ipairs(data[6]) do
				local mail = MailClient.GetMailInfo(v)
				if mail.bItemFlag then
					for i = 0, 7, 1 do
						local item2 = mail.GetItem(i)
						if item2 then
							mail.TakeItem(i)
						end
					end
				end
			end
		end
	end
	AH_Library.DelayCall(0.5, function()
		local szName = GetClientPlayer().szName
		AH_MailBank.Init(frame)
		AH_MailBank.LoadMailData(frame, szName)
	end)
end

function AH_MailBank.OnItemRButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local data = this.data
		local item = GetItem(data[1])
		if item then
			local menu = {}
			local MailClient = GetMailClient()
			for k, v in ipairs(data[6]) do
				local mail = MailClient.GetMailInfo(v)
				local m = {szOption = mail.szTitle}
				if mail.bItemFlag then
					for i = 0, 7, 1 do
						local item2 = mail.GetItem(i)
						if item2 and item2.nUiId == this.nUiId then
							local m_1 = {
								szOption = string.format("%s x%d", item2.szName, item2.nStackNum),
								fnAction = function()
									mail.TakeItem(i)
									AH_Library.DelayCall(0.5, function()
										local szName = GetClientPlayer().szName
										AH_MailBank.LoadMailData(frame, szName)
									end)
								end
							}
							table.insert(m, m_1)
						end
					end
				end
				table.insert(menu, m)
			end
			PopupMenu(menu)
		end
	end
end

function AH_MailBank.OnItemMouseEnter()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local data = this.data
		if IsAltKeyDown() then
			local _, dwID = this:GetObjectData()
			OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, dwID, nil, nil, {x, y, w, h})
		else
			local item = GetItem(data[1])
			if item then
				local szTip = ""
				szTip = szTip .. "<Text>text=" .. EncodeComponentsString(item.szName) .. " font=60" .. GetItemFontColorByQuality(item.nQuality, true) .. " </text>"
				szTip = szTip .. GetFormatText("\n<ALT����ʾ��Ʒ��Ϣ��������ȫ��ʰȡ���Ҽ�����ּ�ʰȡ>", 165)
				local MailClient = GetMailClient()
				for k, v in ipairs(data[6]) do
					local mail = MailClient.GetMailInfo(v)
					szTip = szTip .. GetFormatText(string.format("\n\n%s", mail.szSenderName), 164)
					szTip = szTip .. GetFormatText(string.format(" ��%s��\n", mail.szTitle), 163)
					local szLeft = AH_MailBank.FormatItemLeftTime(mail.GetLeftTime())
					szTip = szTip .. GetFormatText(string.format("ʣ��ʱ�䣺%s", szLeft), 162)
					local nCount = AH_MailBank.GetMailItem(v)[this.nUiId][5]
					szTip = szTip .. GetFormatText(string.format("  ������%d", nCount), 162)
				end
				OutputTip(szTip, 300, {x, y, w, h})
			end
		end
	end
end

function AH_MailBank.OnItemMouseLeave()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end

	this:SetObjectMouseOver(0)
	HideTip()
end

function AH_MailBank.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_MailBank")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_MailBank.OpenPanel()
	local frame = nil
	if not AH_MailBank.IsPanelOpened()  then
		frame = Wnd.OpenWindow(szIniFile, "AH_MailBank")
		AH_MailBank.Init(frame)
		local szName = GetClientPlayer().szName
		AH_MailBank.LoadMailData(frame, szName)
	else
		AH_MailBank.ClosePanel()
	end
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_MailBank.ClosePanel()
	if AH_MailBank.IsPanelOpened() then
		Wnd.CloseWindow("AH_MailBank")
	end
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

--~ RegisterEvent("MAIL_LIST_UPDATE", function()
--~ 	if AH_MailBank.IsPanelOpened() then
--~ 		local frame = Station.Lookup("Normal/AH_MailBank")
--~ 		local szName = GetClientPlayer().szName
--~ 		AH_MailBank.tItemCache[szName] = AH_MailBank.SaveItemCache()
--~ 		AH_MailBank.LoadMailData(frame, szName)
--~ 	end
--~ end)

RegisterEvent("LOGIN_GAME", function()
	if IsFileExist(AH_MailBank.szDataPath) then
		AH_MailBank.tItemCache = LoadLUAData(AH_MailBank.szDataPath)
	end
end)

RegisterEvent("GAME_EXIT", function()
	SaveLUAData(AH_MailBank.szDataPath, AH_MailBank.tItemCache)
end)

RegisterEvent("PLAYER_EXIT_GAME", function()
	SaveLUAData(AH_MailBank.szDataPath, AH_MailBank.tItemCache)
end)

AH_Library.RegisterBreatheEvent("ON_AH_MAILBANK_UPDATE", AH_MailBank.OnUpdate)
