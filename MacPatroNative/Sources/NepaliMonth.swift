import Foundation

enum NepaliMonth: Int {
    case Baisakh = 1, Jestha, Ashadh, Shrawan, Bhadra, Ashwin, Kartik, Mangsir, Poush, Magh, Falgun, Chaitra

    var name: String {
        switch self {
        case .Baisakh: return "वैशाख"
        case .Jestha: return "जेठ"
        case .Ashadh: return "असार"
        case .Shrawan: return "साउन"
        case .Bhadra: return "भदौ"
        case .Ashwin: return "असोज"
        case .Kartik: return "कार्तिक"
        case .Mangsir: return "मंसिर"
        case .Poush: return "पुस"
        case .Magh: return "माघ"
        case .Falgun: return "फागुन"
        case .Chaitra: return "चैत"
        }
    }
}
