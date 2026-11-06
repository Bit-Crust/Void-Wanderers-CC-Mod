function Create(self)
	self.attachSound = CreateSoundContainer(
		self:StringValueExists("AttachSound") and self:GetStringValue("AttachSound") or "Robot Stride"
	)
	self.errorSound = CreateSoundContainer("Error")
end

function Update(self)
	if self:IsActivated() then
		if not self.wasActivated then
			local parent = self:GetRootParent()
			local success = false

			if IsActor(parent) then
				parent = ToActor(parent)

				local moCheck = SceneMan:CastMORay(
					self.MuzzlePos,
					Vector(self.Radius * self.FlipFactor * 2, 0):RadRotate(self.RotAngle),
					parent.ID,
					Activity.NOTEAM,
					rte.grassID,
					true,
					4
				)
				local target = moCheck ~= rte.NoMOID and MovableMan:GetMOFromID(moCheck)

				if target and IsAHuman(target:GetRootParent()) then
					local human = ToAHuman(target:GetRootParent())

					if
						not CF["RefuseBrain"](human, parent)
						and human:IsDead()
						and human.Team ~= parent.Team
						and human.Head
					then
						human:FlashWhite(50)
						self.attachSound:Play(human.Pos)
						self:GetParent():RemoveAttachable(self, false, false)
						human.Team = parent.Team
						success = true
					end
				end
			end

			if not success then
				self.errorSound:Play(self.Pos)
			end
		end

		self.wasActivated = true
		self:Deactivate()
	else
		self.wasActivated = false
	end
end
