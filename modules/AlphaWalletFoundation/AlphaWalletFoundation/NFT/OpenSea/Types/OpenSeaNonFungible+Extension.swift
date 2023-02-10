// Copyright © 2018 Stormbird PTE. LTD.

import Foundation
import AlphaWalletOpenSea
import BigInt
import SwiftyJSON

extension NftAsset {
    var tokenIdSubstituted: String {
        return TokenIdConverter.toTokenIdSubstituted(string: tokenId)
    }

    mutating func update(enjinToken: GetEnjinTokenQuery.Data.EnjinToken) {
        meltStringValue = enjinToken.meltValue
        meltFeeRatio = enjinToken.meltFeeRatio
        meltFeeMaxRatio = enjinToken.meltFeeMaxRatio
        totalSupplyStringValue = enjinToken.totalSupply
        circulatingSupplyStringValue = enjinToken.circulatingSupply
        reserveStringValue = enjinToken.reserve
        nonFungible = enjinToken.nonFungible
        blockHeight = enjinToken.blockHeight
        mintableSupply = enjinToken.mintableSupply.flatMap { BigInt($0) }
        transferable = enjinToken.transferable?.rawValue
        supplyModel = enjinToken.supplyModel?.rawValue
        issuer = enjinToken.creator
        created = enjinToken.createdAt
        transferFee = enjinToken.transferFeeSettings?.type?.rawValue
    }
}

extension JSON {
    mutating func update(enjinToken: GetEnjinTokenQuery.Data.EnjinToken) {
        self["meltStringValue"] = JSON(enjinToken.meltValue as Any)
        self["meltFeeRatio"] = JSON(enjinToken.meltFeeRatio as Any)
        self["meltFeeMaxRatio"] = JSON(enjinToken.supplyModel as Any)
        self["supplyModel"] = JSON(enjinToken.supplyModel as Any)
        self["totalSupplyStringValue"] = JSON(enjinToken.totalSupply as Any)
        self["circulatingSupplyStringValue"] = JSON(enjinToken.circulatingSupply as Any)
        self["reserveStringValue"] = JSON(enjinToken.reserve as Any)
        self["transferable"] = JSON(enjinToken.transferable as Any)
        self["nonFungible"] = JSON(enjinToken.nonFungible as Any)
        self["blockHeight"] = JSON(enjinToken.blockHeight as Any)
        self["mintableSupply"] = JSON(enjinToken.mintableSupply as Any)
        self["enjin.issuer"] = JSON(enjinToken.creator as Any)
        self["created"] = JSON(enjinToken.createdAt as Any)
        self["transferFee"] = JSON(enjinToken.transferFeeSettings?.type?.rawValue as Any)
    }
}

struct TokenIdConverter {
    static func toTokenIdSubstituted(string: String) -> String {
        if let tokenId = BigInt(string) {
            let string = String(tokenId, radix: 16)
            return TokenIdConverter.addTrailingZerosPadding(string: string)
        } else {
            return string
        }
    }

    static func addTrailingZerosPadding(string: String) -> String {
        return string.padding(toLength: 64, withPad: "0", startingAt: 0)
    }
}

struct OpenSeaNonFungibleBeforeErc1155Support: Codable {
    //Not every token might used the same name. This is just common in OpenSea
    public static let generationTraitName = "generation"
    public static let cooldownIndexTraitName = "cooldown_index"

    let tokenId: String
    let contractName: String
    let symbol: String
    let name: String
    let description: String
    let thumbnailUrl: String
    let imageUrl: String
    let contractImageUrl: String
    let externalLink: String
    let backgroundColor: String?
    let traits: [OpenSeaNonFungibleTrait]
    var generationTrait: OpenSeaNonFungibleTrait? {
        return traits.first { $0.type == NftAsset.generationTraitName }
    }

    func asPostErc1155Support(tokenType: NonFungibleFromJsonTokenType?) -> NonFungibleFromJson {
        let result = NftAsset(tokenId: tokenId, tokenType: tokenType ?? .erc721, value: 1, contractName: contractName, decimals: 0, symbol: symbol, name: name, description: description, thumbnailUrl: thumbnailUrl, imageUrl: imageUrl, contractImageUrl: contractImageUrl, externalLink: externalLink, backgroundColor: backgroundColor, traits: traits, collectionCreatedDate: nil, collectionDescription: nil, creator: nil, collectionId: "", imageOriginalUrl: "", previewUrl: "")
        return result
    }
}
