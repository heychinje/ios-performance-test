//
//  SilentAudioGenerator.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/7/8.
//

/// Generates silent audio data for background execution
struct SilentAudioGenerator {
    
    static func createSilentAudioData() -> Data? {
        var audioData = Data()
        
        // WAV header for 1 second of silence (44100 Hz, 16-bit, mono)
        let wavHeader: [UInt8] = [
            0x52, 0x49, 0x46, 0x46, // "RIFF"
            0x24, 0x08, 0x00, 0x00, // ChunkSize
            0x57, 0x41, 0x56, 0x45, // "WAVE"
            0x66, 0x6D, 0x74, 0x20, // "fmt "
            0x10, 0x00, 0x00, 0x00, // Subchunk1Size
            0x01, 0x00,             // AudioFormat (PCM)
            0x01, 0x00,             // NumChannels (mono)
            0x44, 0xAC, 0x00, 0x00, // SampleRate (44100)
            0x88, 0x58, 0x01, 0x00, // ByteRate
            0x02, 0x00,             // BlockAlign
            0x10, 0x00,             // BitsPerSample
            0x64, 0x61, 0x74, 0x61, // "data"
            0x00, 0x08, 0x00, 0x00  // Subchunk2Size
        ]
        
        audioData.append(contentsOf: wavHeader)
        
        // Add 1 second of silence (44100 samples * 2 bytes)
        let silenceBuffer = Data(count: 88200)
        audioData.append(silenceBuffer)
        
        return audioData
    }
}
