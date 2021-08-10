//
//  main.swift
//  LZMA-SDB
//
//  Created by Scott D. Bowen on 10/8/21.
//

import Foundation
import DataCompression

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}
extension DataConvertible where Self: ExpressibleByIntegerLiteral{

    init?(data: Data) {
        var value: Self = 0
        guard data.count == MemoryLayout.size(ofValue: value) else { return nil }
        _ = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }

    var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}
extension UInt8 : DataConvertible { }

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}
extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
}

/* actor Compressed {
    var chunk: UInt32 = UInt32.max
    var data: Data = Data()
    
    func addData(newData: Data) async -> Int {
        self.data.append(newData)
        return newData.count
    }
    func dataLength(newData: Data) -> Int {
        return newData.count
    }
    func saveData(fileURL: URL) {
        do {
            try data.write(to: fileURL)
        } catch {
            print("Error while saving data to file.")
        }
    }
} */

print("Hello, World!")
let date_start = Date()

let fileURL = URL(fileURLWithPath: "/Users/sdb/Testing/enwik8")
let enwik_Test: [UInt8] = try Data(contentsOf: fileURL).bytes
let enwik_Test_SMT16 = enwik_Test.chunked(into: enwik_Test.count / 16)

var dataToCompress: [Data] = [Data(enwik_Test_SMT16[0].data),
                               Data(enwik_Test_SMT16[1].data),
                               Data(enwik_Test_SMT16[2].data),
                               Data(enwik_Test_SMT16[3].data),
                               Data(enwik_Test_SMT16[4].data),
                               Data(enwik_Test_SMT16[5].data),
                               Data(enwik_Test_SMT16[6].data),
                               Data(enwik_Test_SMT16[7].data),
                               Data(enwik_Test_SMT16[8].data),
                               Data(enwik_Test_SMT16[9].data),
                               Data(enwik_Test_SMT16[10].data),
                               Data(enwik_Test_SMT16[11].data),
                               Data(enwik_Test_SMT16[12].data),
                               Data(enwik_Test_SMT16[13].data),
                               Data(enwik_Test_SMT16[14].data),
                               Data(enwik_Test_SMT16[15].data)]


let serialQueue = DispatchQueue(label: "Serial Queue") // custom dispatch queues are serial by default

DispatchQueue.concurrentPerform(iterations: 16, execute: { iterGCD in
    print("\(iterGCD): raw   =>   \(enwik_Test_SMT16[iterGCD].count) bytes")

    for algo: Data.CompressionAlgorithm in [.lzma] { // [.lzma, .zlib, .lzfse, .lz4,]
        dataToCompress[iterGCD] = dataToCompress[iterGCD].compress(withAlgorithm: algo)!
        // let OK = compressed.addData(newData: newCompressedData)
        let ratio = Double(enwik_Test_SMT16[iterGCD].count) / Double(dataToCompress[iterGCD].count)
        print("\(iterGCD): \(algo)   =>   \(dataToCompress[iterGCD].count) bytes, ratio: \(ratio)")
        assert(dataToCompress[iterGCD].decompress(withAlgorithm: algo)! == enwik_Test_SMT16[iterGCD].data)
        
        // TODO: ??? assert(compressedDataArray[iterGCD].decompress(withAlgorithm: algo) == enwik9_SMT16[iterGCD].data)
    }
})

serialQueue.sync {
    let outputURL = URL(fileURLWithPath: "/Users/sdb/Testing/enwik8.output.LZMA-SDB")
    do {
        try dataToCompress.compactMap{$0}.first!.write(to: outputURL)
        print("Saved data to file.")
    } catch {
        print("Error while saving data to file.")
    }
}

print()
print("\(-date_start.timeIntervalSinceNow) seconds")

print("Goodbye.")
sleep(10)
