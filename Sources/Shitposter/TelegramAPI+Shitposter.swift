import Foundation

extension TelegramAPI {
    var logged: TelegramAPI {
        TelegramAPILogger(decoratee: self)
    }
    
    var retry: TelegramAPI {
        TelegramAPIRetry(decoratee: self)
    }
    
    func fallback(to: TelegramAPI, condition: @escaping (Error) -> Bool) -> TelegramAPI {
        TelegramAPIDecorator(primary: self, secondary: to, condition: condition)
    }
}
