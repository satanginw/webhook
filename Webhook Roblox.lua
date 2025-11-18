-- ================================================================= --
--                             Configuration & Dependencies          --
-- ================================================================= --

-- ** 🚩 Webhook Settings (ใช้ค่าล่าสุดที่คุณกำหนด) **
_G.WebhookLink = "https://ptb.discord.com/api/webhooks/1437711817001402389/ofuK3rA17hrRcHo9JuyT0Q6TlG92eT1O_5m0njdfzmEEw6adU3bM8Gn_vLZNzUNF6wh3" -- ลิ้งเว็บฮุค
_G.Webhookdelay = 600 -- 60 วินาที
_G.EnabledSendWebhook = true

-- ** Services & Variables ที่จำเป็น **
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Client = Players.LocalPlayer
local PlayerGui = Client.PlayerGui

-- ** Module ที่จำเป็น **
local Net = require(ReplicatedStorage.Modules.Core.Net)

-- ** ฟังก์ชัน Global ที่จำเป็น **
local function c()
	return _G
end
-- hookfunction, request, game:HttpGet ถูกเรียกใช้โดยตรง


-- ================================================================= --
--                           Helper Functions (ดึงข้อมูลสถานะ)        --
-- ================================================================= --

local function HandMoney()
	-- ดึงเงินในมือ
	local MoneyTextLabel = PlayerGui.TopRightHud.Holder.Frame.MoneyTextLabel
    if MoneyTextLabel and MoneyTextLabel:IsA("TextLabel") then
        return tonumber(MoneyTextLabel.Text:match("%$(%d+)"))
    end
    return 0
end

local function ATMMoney()
	-- ดึงเงินในธนาคาร
	for i,v in pairs(PlayerGui:GetDescendants()) do
		if v:IsA("TextLabel") then
			if string.find(v.Text,"Bank Balance") then
				return tonumber(v.Text:match("%$(%d+)"))
			end
		end
	end
    return 0
end

function GetLevel()
	-- ดึง Level รวม
	local Level = 0
	local OptionsSkill = PlayerGui:FindFirstChild('Skills')
	if not OptionsSkill then return 0 end
	local ScrollFrame = OptionsSkill:FindFirstChild('SkillsHolder'):FindFirstChild('SkillsScrollingFrame')
	if not ScrollFrame then return 0 end

	for _, v in pairs(ScrollFrame:GetChildren()) do
		if v.Name == 'PlayerCard' then
			local text = v:FindFirstChild('SkillPlayerName')
			if text and text:IsA('TextLabel') then
				Level = tonumber(text.Text:match('%d+')) or 0
			end
		end
	end
	return Level
end

local function GetSkill(skillname)
	-- ดึง Skill Level เฉพาะ
	local Skill = 0
	local OptionsSkill = PlayerGui:FindFirstChild('Skills')
	if not OptionsSkill then return 0 end
	local Holder = OptionsSkill:FindFirstChild('SkillsHolder').SkillsScrollingFrame
	
	for _, v in pairs(Holder:GetChildren()) do
		if v.Name == 'SkillOptionTemplate' then
			if v:FindFirstChild('SkillTitle') and string.find(v.SkillTitle.Text, skillname) then
				Skill = tonumber(v.SkillTitle.Text:match('%d+'))
			end
		end
	end
	return Skill
end


-- ================================================================= --
--                           Webhook Logics                          --
-- ================================================================= --

-- 1. Webhook for being Kicked (hook Client.Kick)
hookfunction(Client.Kick,function()
	local success, errors = pcall(function()
        print("[Webhook] กำลังส่ง Webhook แจ้งเตือน: ถูกเตะ (Kick)...")
		local embed = {
			['title'] = '🎮 [ Block Spin ] SL-SHOP INWROBLOX!!',
			['description'] = '```diff\n+ '
				.. Client.Name
				.. ' got kicked gonna rejoin \n```',
			['color'] = tonumber(0xFF6B35),
			['footer'] = {
				['text'] = '🧑‍💼 SL-SHOP INWROBLOX',
			},
			['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ'),
		}

		local embedData = { ['content'] = '@everyone', ['embeds'] = { embed } }
		local Result = request({
			Url = c().WebhookLink or "",
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
			},
			Body = HttpService:JSONEncode(embedData),
		})

        if Result then
            print("[Webhook] ส่ง Webhook แจ้งเตือนถูกเตะ สำเร็จ!")
        else
            print("[Webhook] ส่ง Webhook แจ้งเตือนถูกเตะ ล้มเหลว!")
        end

		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Client)
	end)
	if not success then
		print("[Webhook] เกิด Error ภายใน hookfunction Client.Kick: " .. tostring(errors))
	end
end)


-- 2. Webhook for being Banned (hook Net.get)
local OldNetGet = Net.get

Net.get = function(...)
	local args = { ... }
	if args[1] == 'invalid_entry' then
		local success, errors = pcall(function()
            print("[Webhook] กำลังส่ง Webhook แจ้งเตือน: ถูกแบน (Net.get 'invalid_entry')...")
			local embed = {
				['title'] = '🎮 [ Block Spin ] SL-SHOP INWROBLOX Notify!!',
				['description'] = '```diff\n- '
					.. Client.Name
					.. ' got Banned \n```',
				['color'] = tonumber(0xFF6B35),
				['footer'] = {
					['text'] = '🧑‍💼 SL-SHOP INWROBLOX',
				},
				['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ'),
			}

			local embedData = { ['content'] = '@everyone', ['embeds'] = { embed } }
			local Result = request({
				Url = c().WebhookLink or "",
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json',
				},
				Body = HttpService:JSONEncode(embedData),
			})

            if Result then
                print("[Webhook] ส่ง Webhook แจ้งเตือนถูกแบน สำเร็จ!")
            else
                print("[Webhook] ส่ง Webhook แจ้งเตือนถูกแบน ล้มเหลว!")
            end
		end)
		if not success then
			print("[Webhook] เกิด Error ภายใน Net.get hook: " .. tostring(errors))
		end
	end
	return OldNetGet(unpack(args))
end


-- 3. Webhook for Periodic Player Status Update (ทุกๆ 60 วินาที)
task.spawn(function()
    print("[Webhook INIT] เริ่มการทำงานของ Webhook Status Loop (Delay: " .. c().Webhookdelay .. "s)...")
	while task.wait(c().Webhookdelay or 60) do
		if not c().EnabledSendWebhook then break end

		local success, errors = pcall(function()
            print("[Webhook] กำลังส่ง Webhook แจ้งสถานะผู้เล่น...")

			local embed = {
				['title'] = '🎮 [ Block Spin ] SL-SHOP INWROBLOX Notify!!',
				['description'] = '```diff\n+ Player Status Updated\n```',
				['color'] = tonumber(0xFF6B35),
				['fields'] = {
					{
						['name'] = '👤 Player Information',
						['value'] = string.format(
							'```yaml\n'
							.. 'Name: %s\n'
							.. 'Display: %s\n'
							.. 'User ID: %d\n```',
							Client.Name,
							Client.DisplayName,
							Client.UserId
						),
						['inline'] = false,
					},
					{
						['name'] = '💰 Money Status',
						['value'] = string.format(
							'```fix\n'
							.. '💵 Hand Money: %s\n'
							.. '🏦 Bank Balance: %s\n```',
							tostring(HandMoney()),
							tostring(ATMMoney())
						),
						['inline'] = false,
					},

					{
						['name'] = '📊 Level & Skills',
						['value'] = string.format(
							'```ini\n'
							.. '[⭐ Total Level] = %d\n'
							.. '[📦 Shelf Stocker] = %d\n'
							.. '[🍚 Cook] = %d\n'
							.. '[🧹 Janitor] = %d\n'
							.. '[🌀 Swiper] = %d\n'
							.. '[💪 Stamina] = %d\n```',
							GetLevel() or 0,
							GetSkill('Shelf Stocker') or 0,
							GetSkill('Cook') or 0,
							GetSkill('Janitor') or 0,
							GetSkill('Swiper') or 0,
							GetSkill('Stamina') or 0
						),
						['inline'] = false,
					},
				},
				['footer'] = {
					['text'] = '🧑‍💼 SL-SHOP INWROBLOX',
				},
				['timestamp'] = os.date('!%Y-%m-%dT%H:%M:%SZ'),
			}
			local embedData = { ['content'] = 'Current Player Status', ['embeds'] = { embed } }

			local Result = request({
                Url = c().WebhookLink or "",
                Method = 'POST',
                Headers = {
                    ['Content-Type'] = 'application/json',
                },
                Body = HttpService:JSONEncode(embedData),
            })

            if Result then
                print("[Webhook] ส่ง Webhook แจ้งสถานะผู้เล่น สำเร็จ!")
            else
                print("[Webhook] ส่ง Webhook แจ้งสถานะผู้เล่น ล้มเหลว! (ตรวจสอบ Webhook Link หรือปัญหาจาก Executor)")
            end

		end)
		if not success then
            print("[Webhook] เกิด Error ภายใน Status Update Loop: " .. tostring(errors))
        end
	end
end)