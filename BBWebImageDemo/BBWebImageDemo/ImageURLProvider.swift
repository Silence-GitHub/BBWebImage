//
//  ImageURLProvider.swift
//  BBWebImageDemo
//
//  Created by Kaibo Lu on 2018/11/7.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit

class ImageURLProvider {
    static func originURL(forIndex index: Int) -> URL? {
        if index < 1 || index > 4000 { return nil }
        return URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/origin/\(index).jpg")
    }
    
    static func thumbnailURL(forIndex index: Int) -> URL? {
        if index < 1 || index > 4000 { return nil }
        return URL(string: "http://qzonestyle.gtimg.cn/qzone/app/weishi/client/testimage/64/\(index).jpg")
    }
    
    static let gifUrlStrings: [String] = ["https://media.tenor.com/images/962877f1845be69d8fa026fbab9916a0/tenor.gif",
                                          "https://media.tenor.com/images/cd4582aea4d353f63a21173dc9b7f473/tenor.gif",
                                          "https://media.tenor.com/images/18b767b668c6cf5bbb1b7d2c062c8060/tenor.gif",
                                          "https://media.tenor.com/images/f23b91c43cf0226de25dd0a038e2b2f1/tenor.gif",
                                          "https://media.tenor.com/images/ea4c3f7c28dbf0df7ad360c131bb498d/tenor.gif",
                                          "https://media.tenor.com/images/1b7632f1262560f8a5e47de62dc73b59/tenor.gif",
                                          "https://media.tenor.com/images/cb6559e9792575a1e2009eee941f87fe/tenor.gif",
                                          "https://media.tenor.com/images/564eac526a8af795c90ce5985904096e/tenor.gif",
                                          "https://media.tenor.com/images/06d6db1e93a871969e3eea81bfc9fa50/tenor.gif",
                                          "https://media.tenor.com/images/39fe167bdab90223bcc890bcb067b761/tenor.gif",
                                          "https://media.tenor.com/images/9b7a98b5f9f291c159932ad0f1017371/tenor.gif",
                                          "https://media.tenor.com/images/75cbeab79db94fcb8ac290fea6adc460/tenor.gif",
                                          "https://media.tenor.com/images/365b23d03382e5e55a6e167f6a799c4d/tenor.gif",
                                          "https://media.tenor.com/images/760e847e679d53e49ced6037a082a816/tenor.gif",
                                          "https://media.tenor.com/images/e70b1a9ae0f033842c65ec3767c378be/tenor.gif",
                                          "https://media.tenor.com/images/86cf2396ee6061a6fa0611e985dcd65e/tenor.gif",
                                          "https://media.tenor.com/images/0a1652de311806ce55820a7115993853/tenor.gif",
                                          "https://media.tenor.com/images/d5184d27a706ed2e0b4ce3d84cf1042e/tenor.gif",
                                          "https://media.tenor.com/images/a8bd8babbd88ad4e5970a82807199189/tenor.gif",
                                          "https://media.tenor.com/images/6f231aba330e3bfa12619c7793b8a5af/tenor.gif",
                                          "https://media.tenor.com/images/75f98e2557c9f5fc3b00c74fe6f8c76b/tenor.gif",
                                          "https://media.tenor.com/images/c21b647c80cb7d6ca565b19dc05e207e/tenor.gif",
                                          "https://media.tenor.com/images/e9248dace68a025d11d3c654eb818f88/tenor.gif",
                                          "https://media.tenor.com/images/2c6dd2e205270eab39de4d03e318d9c6/tenor.gif",
                                          "https://media.tenor.com/images/78c82748b18f8abd051c41575f38fe53/tenor.gif",
                                          "https://media.tenor.com/images/442e6fae848e8dd15c9dda9fa17dc350/tenor.gif",
                                          "https://media.tenor.com/images/d208d57e1c031e7222136a96e95de8e8/tenor.gif",
                                          "https://media.tenor.com/images/2a1b8680f6c7df066559a2525b350334/tenor.gif",
                                          "https://media.tenor.com/images/bfe7558f4b14327b310db8e51e6e88d3/tenor.gif",
                                          "https://media.tenor.com/images/85ecd6e71d0b2a4c4efa4cbb18137ddf/tenor.gif",
                                          "https://media.tenor.com/images/d6b57d4ce2b21b61cf494fbf4721a149/tenor.gif",
                                          "https://media.tenor.com/images/df6b7e056671877d0cc3929b3a7b2d64/tenor.gif",
                                          "https://media.tenor.com/images/0098a5aeb247ab5875cff39109218294/tenor.gif",
                                          "https://media.tenor.com/images/02a0bf15d16c8120c83612fec4f17e35/tenor.gif",
                                          "https://media.tenor.com/images/7d76faa433d69f2be3444192edc1f598/tenor.gif",
                                          "https://media.tenor.com/images/37f6bfcc95057bcf8d287d10f4c001b6/tenor.gif",
                                          "https://media.tenor.com/images/14fc3ea7825b6c54243d6b546ffab244/tenor.gif",
                                          "https://media.tenor.com/images/37a402b5fea425f3f488d7d847245178/tenor.gif",
                                          "https://media.tenor.com/images/299f0acf758d21b60f4df02c7997df1e/tenor.gif",
                                          "https://media.tenor.com/images/c5caf59fd029c206db34cbb14956b8e2/tenor.gif",
                                          "https://media.tenor.com/images/7f84982680a2b1b612ae477f48f8850b/tenor.gif",
                                          "https://media.tenor.com/images/603c6bd46d5b546cda6f0796bb3cddb5/tenor.gif",
                                          "https://media.tenor.com/images/4883785b43817c19b2448f95c16b0e4e/tenor.gif",
                                          "https://media.tenor.com/images/7709345e06d06256965591bcce4d8e38/tenor.gif",
                                          "https://media.tenor.com/images/d2a66d5463d62d8bdc190e0133783a92/tenor.gif",
                                          "https://media.tenor.com/images/d570d81cb1ea53a303d3a6c159093489/tenor.gif",
                                          "https://media.tenor.com/images/f96ea4941ff858fd97aaba53e8bcad63/tenor.gif",
                                          "https://media.tenor.com/images/e8677cc3a05834495892a27e62e0524b/tenor.gif",
                                          "https://media.tenor.com/images/bc0111bb2ddb755bf1a90df4d05476dc/tenor.gif",
                                          "https://media.tenor.com/images/a1414dc8cc99aa2fe3361b36d5a7a6ff/tenor.gif",
                                          "https://media.tenor.com/images/418607319fe403dac0d481793aebddea/tenor.gif",
                                          "https://media.tenor.com/images/e9db003894d585aec6f51a13b912bdbf/tenor.gif",
                                          "https://media.tenor.com/images/d44281c288ce02b21ecd842fa6a08682/tenor.gif",
                                          "https://media.tenor.com/images/f40633214ffdacfae411aee8cb0cc6e3/tenor.gif",
                                          "https://media.tenor.com/images/4419813fa79e17729803a407bd5ccd6d/tenor.gif",
                                          "https://media.tenor.com/images/d08eed3f9ddbede8f033cd0adc45c2a6/tenor.gif",
                                          "https://media.tenor.com/images/2061d5a4023680ebe52e9e868b406ef2/tenor.gif",
                                          "https://media.tenor.com/images/7d775a755c0a37bb02b3778b647ccc2c/tenor.gif",
                                          "https://media.tenor.com/images/fc592ec5813f2e71034e190984a4cd67/tenor.gif",
                                          "https://media.tenor.com/images/63dbc4465fe981930bf1367ae472041d/tenor.gif",
                                          "https://media.tenor.com/images/c674ba98c40f6793eaf10a1356c1c36a/tenor.gif",
                                          "https://media.tenor.com/images/431eb67b27100729571ff6ae4421a428/tenor.gif"]
    
    static func gifURL(forIndex index: Int) -> URL? {
        if index < 0 || index >= gifUrlStrings.count { return nil }
        return URL(string: gifUrlStrings[index])
    }
}
