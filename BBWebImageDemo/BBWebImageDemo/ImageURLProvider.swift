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
                                          "https://media.tenor.com/images/431eb67b27100729571ff6ae4421a428/tenor.gif",
                                          "https://media.tenor.com/images/c4ef3bef18c1f73d620933d8edcde70d/tenor.gif",
                                          "https://media.tenor.com/images/06c3b7485f9faee9bda5fa0afe548339/tenor.gif",
                                          "https://media.tenor.com/images/b3fa3e23470374ab460a2efe6e5e9c51/tenor.gif",
                                          "https://media.tenor.com/images/6f567ef7cae93ca76de2346f28764ee9/tenor.gif",
                                          "https://media.tenor.com/images/c9b4f67a5313017a397a2ce7d51e87d8/tenor.gif",
                                          "https://media.tenor.com/images/96d132309f2874d32060dd5fb6534a49/tenor.gif",
                                          "https://media.tenor.com/images/280056b1dc40deea3bf1131f6b9a1aa1/tenor.gif",
                                          "https://media.tenor.com/images/c5316b8e4243e9844a085ad8d2cba02f/tenor.gif",
                                          "https://media.tenor.com/images/a045cf84f40dd696e64ccc7a886e64d5/tenor.gif",
                                          "https://media.tenor.com/images/5b815a9ea9f95f8b6b2c7336e41008cf/tenor.gif",
                                          "https://media.tenor.com/images/dc385f8b73d4c142c89612e807ae03b6/tenor.gif",
                                          "https://media.tenor.com/images/84910563686a3634809db115d4c7ee54/tenor.gif",
                                          "https://media.tenor.com/images/94b745dc276f255c312ac5ef78078821/tenor.gif",
                                          "https://media.tenor.com/images/fc13373a669f8a7ea2ba6357baa081bd/tenor.gif",
                                          "https://media.tenor.com/images/58da3874fbf792c6682bdbb577052e9d/tenor.gif",
                                          "https://media.tenor.com/images/005154c18dde991c74dec778e2a11032/tenor.gif",
                                          "https://media.tenor.com/images/5418f54dcd58cbd5487d0dec9e644d1a/tenor.gif",
                                          "https://media.tenor.com/images/0b2e8973ec3973837672e19df74f09ff/tenor.gif",
                                          "https://media.tenor.com/images/ceafd8f4497e8552cadb675236a8f2d1/tenor.gif",
                                          "https://media.tenor.com/images/4d7b365a146558106374018fd438f2af/tenor.gif",
                                          "https://media.tenor.com/images/5cb1114e4f1a94c33812a2c332da0c3a/tenor.gif",
                                          "https://media.tenor.com/images/05de333b038141f6b8208c7ce8f8613c/tenor.gif",
                                          "https://media.tenor.com/images/8c2c9a1c609bb055e79a1fc14dd3e6f2/tenor.gif",
                                          "https://media.tenor.com/images/a50bf70e6391fe701aefd70cf25b4563/tenor.gif",
                                          "https://media.tenor.com/images/ab8bd7abbdf3e1f0e15a58ddf0f769bc/tenor.gif",
                                          "https://media.tenor.com/images/0f44b42afe02eaed61fab75fb3e30f3a/tenor.gif",
                                          "https://media.tenor.com/images/f3e627844fbf59f887e558c31683af5d/tenor.gif",
                                          "https://media.tenor.com/images/1ab6be89d9bd30cc97d47b46dcda19b6/tenor.gif",
                                          "https://media.tenor.com/images/bae9f9ee3bf793a0bb667d8e4ccb9883/tenor.gif",
                                          "https://media.tenor.com/images/6ba045554d917ed1ee96c0ff916f9ca4/tenor.gif",
                                          "https://media.tenor.com/images/3d8eb1e9c497abc46370cee9b55d682f/tenor.gif",
                                          "https://media.tenor.com/images/94fdca75e958652f645f50b3b76c679e/tenor.gif",
                                          "https://media.tenor.com/images/1a51ec5f5858118c1d360dec631cc282/tenor.gif",
                                          "https://media.tenor.com/images/d1a455a115942a372a54cd7ffb2c8182/tenor.gif",
                                          "https://media.tenor.com/images/75491050af5236464061d077827e4bb9/tenor.gif",
                                          "https://media.tenor.com/images/8a371a8468c549920173da0e6c49d490/tenor.gif",
                                          "https://media.tenor.com/images/066961b5affb0a7cf339ba07ea619d6f/tenor.gif",
                                          "https://media.tenor.com/images/daf50d955cff48af3e195865c422d3e2/tenor.gif",
                                          "https://media.tenor.com/images/cb495f1822dbce738d97f669f96721a5/tenor.gif",
                                          "https://media.tenor.com/images/8a5927b8b5e9eaaa4dc8d5677cd70a7a/tenor.gif",
                                          "https://media.tenor.com/images/f254facc0a7431d340bbe647539ea8f1/tenor.gif",
                                          "https://media.tenor.com/images/17e91cf2991314dd78eecec4668476a0/tenor.gif"]
    
    static func gifURL(forIndex index: Int) -> URL? {
        if index < 0 || index >= gifUrlStrings.count { return nil }
        return URL(string: gifUrlStrings[index])
    }
}
