// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract OlfactoryArtFHE is SepoliaConfig {
    struct EncryptedAudienceData {
        uint256 id;
        address viewer;
        euint32 encryptedHeartRate;      // Encrypted heart rate
        euint32 encryptedGalvanicResponse; // Encrypted skin conductance
        euint32 encryptedEmotionScore;    // Encrypted emotion state
        euint32 encryptedAttentionLevel;  // Encrypted attention level
        uint256 timestamp;
    }
    
    struct ScentProfile {
        euint32 encryptedFloral;      // Encrypted floral intensity
        euint32 encryptedWoody;       // Encrypted woody intensity
        euint32 encryptedCitrus;      // Encrypted citrus intensity
        euint32 encryptedSpicy;       // Encrypted spicy intensity
        euint32 encryptedEarthy;      // Encrypted earthy intensity
    }
    
    struct ArtExperience {
        euint32 encryptedScentCombo;  // Encrypted scent combination
        euint32 encryptedIntensity;   // Encrypted overall intensity
        euint32 encryptedDuration;     // Encrypted scent duration
        bool isGenerated;
    }
    
    struct DecryptedExperience {
        uint32 scentCombo;
        uint32 intensity;
        uint32 duration;
        bool isRevealed;
    }

    uint256 public sessionCount;
    mapping(uint256 => EncryptedAudienceData) public audienceData;
    mapping(uint256 => ArtExperience) public artExperiences;
    mapping(uint256 => DecryptedExperience) public decryptedExperiences;
    
    mapping(address => uint256[]) private viewerSessions;
    mapping(uint256 => ScentProfile) public scentProfiles;
    
    mapping(uint256 => uint256) private requestToSessionId;
    
    event SessionStarted(uint256 indexed id, address indexed viewer);
    event ExperienceGenerated(uint256 indexed id);
    event ExperienceDecrypted(uint256 indexed id);
    
    address public artistAdmin;
    
    modifier onlyAdmin() {
        require(msg.sender == artistAdmin, "Not admin");
        _;
    }
    
    constructor() {
        artistAdmin = msg.sender;
        
        // Initialize scent profiles
        scentProfiles[1] = ScentProfile({
            encryptedFloral: FHE.asEuint32(70),
            encryptedWoody: FHE.asEuint32(30),
            encryptedCitrus: FHE.asEuint32(20),
            encryptedSpicy: FHE.asEuint32(10),
            encryptedEarthy: FHE.asEuint32(40)
        });
        
        scentProfiles[2] = ScentProfile({
            encryptedFloral: FHE.asEuint32(20),
            encryptedWoody: FHE.asEuint32(80),
            encryptedCitrus: FHE.asEuint32(10),
            encryptedSpicy: FHE.asEuint32(50),
            encryptedEarthy: FHE.asEuint32(60)
        });
        
        scentProfiles[3] = ScentProfile({
            encryptedFloral: FHE.asEuint32(40),
            encryptedWoody: FHE.asEuint32(40),
            encryptedCitrus: FHE.asEuint32(70),
            encryptedSpicy: FHE.asEuint32(30),
            encryptedEarthy: FHE.asEuint32(20)
        });
    }
    
    /// @notice Start a new olfactory art session
    function startArtSession(
        euint32 encryptedHeartRate,
        euint32 encryptedGalvanicResponse,
        euint32 encryptedEmotionScore,
        euint32 encryptedAttentionLevel
    ) public {
        sessionCount += 1;
        uint256 newId = sessionCount;
        
        audienceData[newId] = EncryptedAudienceData({
            id: newId,
            viewer: msg.sender,
            encryptedHeartRate: encryptedHeartRate,
            encryptedGalvanicResponse: encryptedGalvanicResponse,
            encryptedEmotionScore: encryptedEmotionScore,
            encryptedAttentionLevel: encryptedAttentionLevel,
            timestamp: block.timestamp
        });
        
        artExperiences[newId] = ArtExperience({
            encryptedScentCombo: FHE.asEuint32(0),
            encryptedIntensity: FHE.asEuint32(0),
            encryptedDuration: FHE.asEuint32(0),
            isGenerated: false
        });
        
        decryptedExperiences[newId] = DecryptedExperience({
            scentCombo: 0,
            intensity: 0,
            duration: 0,
            isRevealed: false
        });
        
        viewerSessions[msg.sender].push(newId);
        emit SessionStarted(newId, msg.sender);
    }
    
    /// @notice Generate personalized scent experience
    function generateScentExperience(uint256 sessionId) public {
        EncryptedAudienceData storage data = audienceData[sessionId];
        require(!artExperiences[sessionId].isGenerated, "Already generated");
        
        // Determine scent profile based on emotion
        euint32 scentProfileId = determineScentProfile(data);
        
        // Calculate scent intensity
        euint32 intensity = calculateScentIntensity(data);
        
        // Calculate scent duration
        euint32 duration = calculateScentDuration(data);
        
        artExperiences[sessionId] = ArtExperience({
            encryptedScentCombo: scentProfileId,
            encryptedIntensity: intensity,
            encryptedDuration: duration,
            isGenerated: true
        });
        
        emit ExperienceGenerated(sessionId);
    }
    
    /// @notice Request decryption of scent experience
    function requestExperienceDecryption(uint256 sessionId) public {
        require(audienceData[sessionId].viewer == msg.sender, "Not session owner");
        require(!decryptedExperiences[sessionId].isRevealed, "Already decrypted");
        require(artExperiences[sessionId].isGenerated, "Experience not generated");
        
        ArtExperience storage experience = artExperiences[sessionId];
        
        bytes32[] memory ciphertexts = new bytes32[](3);
        ciphertexts[0] = FHE.toBytes32(experience.encryptedScentCombo);
        ciphertexts[1] = FHE.toBytes32(experience.encryptedIntensity);
        ciphertexts[2] = FHE.toBytes32(experience.encryptedDuration);
        
        uint256 reqId = FHE.requestDecryption(ciphertexts, this.decryptScentExperience.selector);
        requestToSessionId[reqId] = sessionId;
    }
    
    /// @notice Process decrypted scent experience
    function decryptScentExperience(
        uint256 requestId,
        bytes memory cleartexts,
        bytes memory proof
    ) public {
        uint256 sessionId = requestToSessionId[requestId];
        require(sessionId != 0, "Invalid request");
        
        ArtExperience storage aExperience = artExperiences[sessionId];
        DecryptedExperience storage dExperience = decryptedExperiences[sessionId];
        require(aExperience.isGenerated, "Experience not generated");
        require(!dExperience.isRevealed, "Already decrypted");
        
        FHE.checkSignatures(requestId, cleartexts, proof);
        
        (uint32 scentCombo, uint32 intensity, uint32 duration) = 
            abi.decode(cleartexts, (uint32, uint32, uint32));
        
        dExperience.scentCombo = scentCombo;
        dExperience.intensity = intensity;
        dExperience.duration = duration;
        dExperience.isRevealed = true;
        
        emit ExperienceDecrypted(sessionId);
    }
    
    /// @notice Determine scent profile based on audience data
    function determineScentProfile(EncryptedAudienceData storage data) private view returns (euint32) {
        // Higher emotion score selects more complex profiles
        return FHE.cmux(
            FHE.gt(data.encryptedEmotionScore, FHE.asEuint32(70)),
            FHE.asEuint32(3), // Complex profile
            FHE.cmux(
                FHE.gt(data.encryptedEmotionScore, FHE.asEuint32(40)),
                FHE.asEuint32(2), // Medium profile
                FHE.asEuint32(1)  // Simple profile
            )
        );
    }
    
    /// @notice Calculate scent intensity
    function calculateScentIntensity(EncryptedAudienceData storage data) private view returns (euint32) {
        // Intensity based on heart rate and attention level
        euint32 hrFactor = FHE.div(data.encryptedHeartRate, FHE.asEuint32(2));
        euint32 attentionFactor = FHE.div(data.encryptedAttentionLevel, FHE.asEuint32(10));
        
        return FHE.add(hrFactor, attentionFactor);
    }
    
    /// @notice Calculate scent duration
    function calculateScentDuration(EncryptedAudienceData storage data) private view returns (euint32) {
        // Duration based on galvanic response and emotion score
        euint32 gsrFactor = FHE.div(data.encryptedGalvanicResponse, FHE.asEuint32(5));
        euint32 emotionFactor = FHE.div(data.encryptedEmotionScore, FHE.asEuint32(10));
        
        return FHE.add(gsrFactor, emotionFactor);
    }
    
    /// @notice Generate scent mixture
    function generateScentMixture(uint256 sessionId) public view returns (
        euint32 floral,
        euint32 woody,
        euint32 citrus,
        euint32 spicy,
        euint32 earthy
    ) {
        ArtExperience storage experience = artExperiences[sessionId];
        require(experience.isGenerated, "Experience not generated");
        
        ScentProfile storage profile = scentProfiles[FHE.decrypt(experience.encryptedScentCombo)];
        
        // Apply intensity scaling
        floral = FHE.div(
            FHE.mul(profile.encryptedFloral, experience.encryptedIntensity),
            FHE.asEuint32(100)
        );
        
        woody = FHE.div(
            FHE.mul(profile.encryptedWoody, experience.encryptedIntensity),
            FHE.asEuint32(100)
        );
        
        citrus = FHE.div(
            FHE.mul(profile.encryptedCitrus, experience.encryptedIntensity),
            FHE.asEuint32(100)
        );
        
        spicy = FHE.div(
            FHE.mul(profile.encryptedSpicy, experience.encryptedIntensity),
            FHE.asEuint32(100)
        );
        
        earthy = FHE.div(
            FHE.mul(profile.encryptedEarthy, experience.encryptedIntensity),
            FHE.asEuint32(100)
        );
        
        return (floral, woody, citrus, spicy, earthy);
    }
    
    /// @notice Create dynamic scent sequence
    function createDynamicSequence(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        
        // Sequence pattern based on heart rate variability
        return FHE.div(
            FHE.mul(data.encryptedHeartRate, data.encryptedGalvanicResponse),
            FHE.asEuint32(100)
        );
    }
    
    /// @notice Calculate audience engagement
    function calculateEngagement(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        
        return FHE.add(
            FHE.div(data.encryptedAttentionLevel, FHE.asEuint32(10)),
            FHE.div(data.encryptedEmotionScore, FHE.asEuint32(10))
        );
    }
    
    /// @notice Detect emotional response
    function detectEmotionalResponse(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        
        // Emotional response intensity
        return FHE.div(
            FHE.mul(data.encryptedEmotionScore, data.encryptedGalvanicResponse),
            FHE.asEuint32(100)
        );
    }
    
    /// @notice Create scent memory signature
    function createScentSignature(uint256 sessionId) public view returns (euint32) {
        ArtExperience storage experience = artExperiences[sessionId];
        require(experience.isGenerated, "Experience not generated");
        
        // Unique signature based on scent combo and intensity
        return FHE.add(
            experience.encryptedScentCombo,
            FHE.div(experience.encryptedIntensity, FHE.asEuint32(10))
        );
    }
    
    /// @notice Update scent profile
    function updateScentProfile(
        uint32 profileId,
        euint32 floral,
        euint32 woody,
        euint32 citrus,
        euint32 spicy,
        euint32 earthy
    ) public onlyAdmin {
        scentProfiles[profileId] = ScentProfile({
            encryptedFloral: floral,
            encryptedWoody: woody,
            encryptedCitrus: citrus,
            encryptedSpicy: spicy,
            encryptedEarthy: earthy
        });
    }
    
    /// @notice Get encrypted audience data
    function getEncryptedAudienceData(uint256 sessionId) public view returns (
        address viewer,
        euint32 encryptedHeartRate,
        euint32 encryptedGalvanicResponse,
        euint32 encryptedEmotionScore,
        euint32 encryptedAttentionLevel,
        uint256 timestamp
    ) {
        EncryptedAudienceData storage d = audienceData[sessionId];
        return (
            d.viewer,
            d.encryptedHeartRate,
            d.encryptedGalvanicResponse,
            d.encryptedEmotionScore,
            d.encryptedAttentionLevel,
            d.timestamp
        );
    }
    
    /// @notice Get encrypted art experience
    function getEncryptedExperience(uint256 sessionId) public view returns (
        euint32 encryptedScentCombo,
        euint32 encryptedIntensity,
        euint32 encryptedDuration,
        bool isGenerated
    ) {
        ArtExperience storage e = artExperiences[sessionId];
        return (
            e.encryptedScentCombo,
            e.encryptedIntensity,
            e.encryptedDuration,
            e.isGenerated
        );
    }
    
    /// @notice Get decrypted experience
    function getDecryptedExperience(uint256 sessionId) public view returns (
        uint32 scentCombo,
        uint32 intensity,
        uint32 duration,
        bool isRevealed
    ) {
        DecryptedExperience storage e = decryptedExperiences[sessionId];
        return (
            e.scentCombo,
            e.intensity,
            e.duration,
            e.isRevealed
        );
    }
    
    /// @notice Get scent profile
    function getScentProfile(uint32 profileId) public view returns (
        euint32 encryptedFloral,
        euint32 encryptedWoody,
        euint32 encryptedCitrus,
        euint32 encryptedSpicy,
        euint32 encryptedEarthy
    ) {
        ScentProfile storage p = scentProfiles[profileId];
        return (
            p.encryptedFloral,
            p.encryptedWoody,
            p.encryptedCitrus,
            p.encryptedSpicy,
            p.encryptedEarthy
        );
    }
    
    /// @notice Calculate scent harmony
    function calculateScentHarmony(uint256 sessionId) public view returns (euint32) {
        ArtExperience storage experience = artExperiences[sessionId];
        require(experience.isGenerated, "Experience not generated");
        
        ScentProfile storage profile = scentProfiles[FHE.decrypt(experience.encryptedScentCombo)];
        
        // Harmony based on scent balance
        euint32 maxScent = FHE.max(
            FHE.max(profile.encryptedFloral, profile.encryptedWoody),
            FHE.max(profile.encryptedCitrus, FHE.max(profile.encryptedSpicy, profile.encryptedEarthy))
        );
        
        euint32 minScent = FHE.min(
            FHE.min(profile.encryptedFloral, profile.encryptedWoody),
            FHE.min(profile.encryptedCitrus, FHE.min(profile.encryptedSpicy, profile.encryptedEarthy))
        );
        
        return FHE.sub(maxScent, minScent);
    }
    
    /// @notice Create emotional resonance score
    function createEmotionalResonance(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        ArtExperience storage experience = artExperiences[sessionId];
        require(experience.isGenerated, "Experience not generated");
        
        // Resonance between emotion and scent profile
        return FHE.div(
            FHE.mul(data.encryptedEmotionScore, experience.encryptedIntensity),
            FHE.asEuint32(100)
        );
    }
    
    /// @notice Generate olfactory narrative
    function generateOlfactoryNarrative(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        
        // Narrative complexity based on attention and emotion
        return FHE.div(
            FHE.mul(data.encryptedAttentionLevel, data.encryptedEmotionScore),
            FHE.asEuint32(100)
        );
    }
    
    /// @notice Detect scent preference
    function detectScentPreference(uint256 sessionId) public view returns (euint32) {
        ArtExperience storage experience = artExperiences[sessionId];
        require(experience.isGenerated, "Experience not generated");
        
        // Preference based on scent combo and intensity
        return FHE.add(
            experience.encryptedScentCombo,
            FHE.div(experience.encryptedIntensity, FHE.asEuint32(10))
        );
    }
    
    /// @notice Create multisensory signature
    function createMultisensorySignature(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        ArtExperience storage experience = artExperiences[sessionId];
        require(experience.isGenerated, "Experience not generated");
        
        // Signature combining physiological and scent data
        return FHE.add(
            FHE.div(data.encryptedHeartRate, FHE.asEuint32(10)),
            experience.encryptedScentCombo
        );
    }
    
    /// @notice Measure immersive impact
    function measureImmersiveImpact(uint256 sessionId) public view returns (euint32) {
        EncryptedAudienceData storage data = audienceData[sessionId];
        
        // Impact based on physiological responses
        return FHE.div(
            FHE.add(
                FHE.div(data.encryptedHeartRate, FHE.asEuint32(2)),
                FHE.div(data.encryptedGalvanicResponse, FHE.asEuint32(5))
            ),
            FHE.asEuint32(2)
        );
    }
    
    /// @notice Generate art evolution insight
    function generateArtEvolutionInsight() public view returns (euint32) {
        euint32 totalEmotion = FHE.asEuint32(0);
        uint32 sessionCount = 0;
        
        // Aggregate emotion scores across sessions
        for (uint i = 1; i <= sessionCount; i++) {
            if (artExperiences[i].isGenerated) {
                totalEmotion = FHE.add(totalEmotion, audienceData[i].encryptedEmotionScore);
                sessionCount++;
            }
        }
        
        return sessionCount > 0 ? FHE.div(totalEmotion, FHE.asEuint32(sessionCount)) : FHE.asEuint32(0);
    }
}