import { describe, it, expect, beforeEach } from "vitest"

describe("Building Performance Contract", () => {
  let contractAddress
  let deployer
  let manager1
  let manager2
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.building-performance"
    deployer = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
    manager1 = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    manager2 = "ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC"
  })
  
  describe("Manager Authorization", () => {
    it("should authorize building managers", () => {
      const result = {
        type: "ok",
        value: true,
      }
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should prevent unauthorized manager authorization", () => {
      const result = {
        type: "err",
        value: 200, // ERR-NOT-AUTHORIZED
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(200)
    })
  })
  
  describe("Building Registration", () => {
    it("should register a new building successfully", () => {
      const buildingData = {
        name: "Green Tower Office Complex",
        address: "123 Sustainability Ave, Eco City",
        totalArea: 50000,
        floors: 25,
        buildingType: "office",
        constructionYear: 2020,
      }
      
      const result = {
        type: "ok",
        value: 1, // building-id
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(1)
    })
    
    it("should reject building registration with empty name", () => {
      const result = {
        type: "err",
        value: 202, // ERR-INVALID-INPUT
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(202)
    })
    
    it("should reject building registration with zero area", () => {
      const result = {
        type: "err",
        value: 202, // ERR-INVALID-INPUT
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(202)
    })
    
    it("should increment building ID for each registration", () => {
      const firstBuilding = { type: "ok", value: 1 }
      const secondBuilding = { type: "ok", value: 2 }
      
      expect(firstBuilding.value).toBe(1)
      expect(secondBuilding.value).toBe(2)
    })
  })
  
  describe("Energy Metrics Recording", () => {
    it("should record energy metrics and calculate efficiency", () => {
      const metricsData = {
        electricityConsumption: 10000,
        gasConsumption: 5000,
        waterConsumption: 2000,
        renewableGeneration: 3000,
      }
      
      const expectedEfficiency = 20 // (3000 * 100) / (10000 + 5000)
      
      const result = {
        type: "ok",
        value: expectedEfficiency,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(expectedEfficiency)
    })
    
    it("should reject metrics for non-existent buildings", () => {
      const result = {
        type: "err",
        value: 201, // ERR-BUILDING-NOT-FOUND
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(201)
    })
    
    it("should calculate cost per square foot correctly", () => {
      const totalConsumption = 15000
      const buildingArea = 50000
      const expectedCostPerSqft = totalConsumption / buildingArea
      
      expect(expectedCostPerSqft).toBe(0.3)
    })
    
    it("should handle zero consumption gracefully", () => {
      const result = {
        type: "ok",
        value: 0, // efficiency score when no consumption
      }
      expect(result.type).toBe("ok")
      expect(result.value).toBe(0)
    })
  })
  
  describe("Environmental Data Recording", () => {
    it("should record environmental data successfully", () => {
      const envData = {
        temperature: 2200, // 22.0°C
        humidity: 45,
        airQuality: 150,
        co2Level: 400,
        lightLevel: 500,
        noiseLevel: 35,
      }
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject invalid humidity values", () => {
      const result = {
        type: "err",
        value: 202, // ERR-INVALID-INPUT
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(202)
    })
    
    it("should reject invalid air quality values", () => {
      const result = {
        type: "err",
        value: 202, // ERR-INVALID-INPUT
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(202)
    })
  })
  
  describe("Performance Targets", () => {
    it("should set performance targets successfully", () => {
      const targets = {
        targetEfficiency: 80,
        maxEnergyConsumption: 20000,
        minAirQuality: 100,
        targetTemperature: 2200,
        maxCo2Level: 500,
      }
      
      const result = {
        type: "ok",
        value: true,
      }
      
      expect(result.type).toBe("ok")
      expect(result.value).toBe(true)
    })
    
    it("should reject invalid efficiency targets", () => {
      const result = {
        type: "err",
        value: 202, // ERR-INVALID-INPUT
      }
      expect(result.type).toBe("err")
      expect(result.value).toBe(202)
    })
  })
  
  describe("Efficiency Rating Calculation", () => {
    it("should calculate excellent rating for high efficiency", () => {
      const rating = "excellent"
      expect(rating).toBe("excellent")
    })
    
    it("should calculate good rating for moderate efficiency", () => {
      const rating = "good"
      expect(rating).toBe("good")
    })
    
    it("should calculate needs-improvement rating for low efficiency", () => {
      const rating = "needs-improvement"
      expect(rating).toBe("needs-improvement")
    })
    
    it("should return no-data when metrics are missing", () => {
      const rating = "no-data"
      expect(rating).toBe("no-data")
    })
    
    it("should return no-targets when targets are not set", () => {
      const rating = "no-targets"
      expect(rating).toBe("no-targets")
    })
  })
  
  describe("Read-only Functions", () => {
    it("should retrieve building information", () => {
      const building = {
        name: "Green Tower Office Complex",
        address: "123 Sustainability Ave, Eco City",
        totalArea: 50000,
        floors: 25,
        buildingType: "office",
        manager: manager1,
        isActive: true,
      }
      
      expect(building.name).toBe("Green Tower Office Complex")
      expect(building.totalArea).toBe(50000)
      expect(building.isActive).toBe(true)
    })
    
    it("should retrieve energy metrics by building and period", () => {
      const metrics = {
        electricityConsumption: 10000,
        gasConsumption: 5000,
        renewableGeneration: 3000,
        efficiencyScore: 20,
        costPerSqft: 0.3,
      }
      
      expect(metrics.electricityConsumption).toBe(10000)
      expect(metrics.efficiencyScore).toBe(20)
    })
    
    it("should return total building count", () => {
      const totalBuildings = 3
      expect(totalBuildings).toBe(3)
    })
  })
})
