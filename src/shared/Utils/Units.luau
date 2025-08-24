local Units = {}

--- Mass in kilograms (kg)
---
--- `Mass in kilograms` * `Units.Mass_kg` = `Roblox mass`
Units.Mass_kg = 1 / 21.952

-- Length in milimeters (mm)
---
--- `Length in meters` * `1 / (Units.Length_mm / 1000)` = `Roblox studs`
Units.Length_mm = 280

--- Force in newtons (N)
---
--- `Force in newtons` * `Units.Force_N` = `Roblox force`
Units.Force_N = Units.Mass_kg * (1 / (Units.Length_mm / 1000))

--- Stiffness in newtons per meter (N/m)
---
--- `Stiffness in N/m` * `Units.Stiffness_Ndivm` = `Roblox stiffness`
Units.Stiffness_Ndivm = Units.Mass_kg

-- Damping in newton-seconds per meter (N s/m)
---
--- `Damping in N s/m` * `Units.Damping_N_sdivm` = `Roblox damping`
Units.Damping_N_sdivm = Units.Mass_kg

-- Velocity in meters per second (m/s)
---
--- `Velocity in m/s` * `Units.Velocity_mdivs` = `Roblox velocity`
Units.Velocity_mdivs = 1 / (Units.Length_mm / 1000)

-- Torque in newton-meters (Nm)
---
--- `Torque in Nm` * `Units.Torque_nm` = `Roblox torque`
Units.Torque_nm = Units.Force_N / (Units.Length_mm / 1000)

return Units
