class_name Dialogues
extends RefCounted
## Kịch bản hội thoại của hàng xóm — viết sẵn, không dùng AI. Mỗi kịch bản có tên người nói và
## các nút; nút = câu người đó nói + 1..MAX_OPTIONS lựa chọn [câu của Player, nút tiếp theo].
## Bắt đầu ở nút START; lựa chọn trỏ tới END thì kết thúc. Thêm hàng xóm: thêm 1 mục vào ALL
## rồi đặt `dialogue_id` của NeighborHome. Sai tên nút → `problems()` báo (World kiểm lúc debug).

const START: String = "start"
const END: String = ""
const MAX_OPTIONS: int = 4  ## Phím số 1..4.

const ALL: Dictionary = {
	"ba":
	{
		"speaker": "Bác Ba",
		"nodes":
		{
			"start":
			{
				"text": "Chào cháu! Hôm nay sang chơi à?",
				"options":
				[
					["Dạ, cháu sang hỏi thăm bác.", "greet"],
					["Bác ơi, làm sao cho rau lớn nhanh?", "garden"],
					["Gà nhà bác dạo này thế nào ạ?", "chickens"],
					["Cháu chào bác, cháu về ạ.", END],
				],
			},
			"greet":
			{
				"text": "Bác vẫn khoẻ, cảm ơn cháu. Cháu ở một mình có buồn không?",
				"options":
				[
					["Không ạ, cháu bận làm vườn cả ngày.", "busy"],
					["Cũng hơi buồn bác ạ.", "lonely"],
				],
			},
			"busy":
			{
				"text": "Chăm chỉ thế là tốt. Có gì cần cứ sang hỏi bác nhé.",
				"options": [["Dạ, cháu hỏi chuyện khác ạ.", "start"], ["Vâng, cháu về ạ.", END]],
			},
			"lonely":
			{
				"text": "Thế chiều nào rảnh thì sang đây uống trà với bác.",
				"options":
				[
					["Dạ, nhất định rồi ạ!", "start"],
					["Cháu cảm ơn bác, cháu về ạ.", END],
				],
			},
			"garden":
			{
				"text": "Cây chỉ lớn khi đất ẩm. Tưới xong bón phân thì lớn nhanh gấp đôi.",
				"options":
				[
					["Bao lâu thì phải tưới lại ạ?", "water"],
					["Cháu hiểu rồi, cảm ơn bác.", "start"],
				],
			},
			"water":
			{
				"text": "Mỗi lần tưới giữ ẩm chừng nửa phút. Thấy đất nhạt màu là tưới tiếp.",
				"options": [["Dạ, cháu nhớ rồi.", "start"], ["Cháu về tưới cây đây ạ.", END]],
			},
			"chickens":
			{
				"text": "Gà bác dạo này lười đẻ quá. Nhà cháu có cho gà ăn đều không?",
				"options":
				[
					["Ngày nào cháu cũng cho ăn ạ.", "eggs"],
					["Thỉnh thoảng cháu quên bác ạ.", "forget"],
				],
			},
			"eggs":
			{
				"text": "Giỏi! Cho ăn xong chừng nửa phút là có trứng nhặt rồi.",
				"options": [["Dạ.", "start"], ["Cháu về nhặt trứng đây ạ.", END]],
			},
			"forget":
			{
				"text": "Đói thì chúng nó không đẻ đâu. Nhớ ghé chuồng thường xuyên nhé.",
				"options":
				[
					["Vâng ạ, cháu sẽ nhớ.", "start"],
					["Cháu về cho gà ăn ngay đây ạ.", END],
				],
			},
		},
	},
	"lan":
	{
		"speaker": "Cô Lan",
		"nodes":
		{
			"start":
			{
				"text": "Ơ, cháu sang chơi à? Vào sân ngồi đã.",
				"options":
				[
					["Cô đang nấu gì mà thơm thế ạ?", "cook"],
					["Hoa nhà cháu nở rồi đấy cô.", "flowers"],
					["Cháu chỉ ghé qua chào cô thôi ạ.", END],
				],
			},
			"cook":
			{
				"text": "Cô nấu nồi chè đậu đen. Cháu ăn một bát không?",
				"options":
				[
					["Dạ, cháu xin một bát ạ!", "che_yes"],
					["Thôi cô ạ, cháu vừa ăn no.", "che_no"],
				],
			},
			"che_yes":
			{
				"text": "Đây, ăn đi cho mát. Lần sau cô nấu chè hạt sen.",
				"options":
				[
					["Ngon quá, cháu cảm ơn cô!", "start"],
					["Cháu ăn xong rồi, cháu về ạ.", END],
				],
			},
			"che_no":
			{
				"text": "Ừ, lúc nào đói thì sang nhé, cô để phần.",
				"options": [["Vâng ạ.", "start"], ["Cháu chào cô, cháu về ạ.", END]],
			},
			"flowers":
			{
				"text": "Thật à? Cô thích hoa lắm. Cho cô xin một cành được không?",
				"options":
				[
					["Được ạ, lát cháu mang sang.", "gift"],
					["Để hoa nở thêm rồi cháu hái cô nhé.", "later"],
				],
			},
			"gift":
			{
				"text": "Cháu ngoan quá! Cô cảm ơn nhé.",
				"options": [["Có gì đâu cô.", "start"], ["Cháu về hái hoa cho cô đây.", END]],
			},
			"later":
			{
				"text": "Ừ, không vội đâu cháu.",
				"options": [["Dạ.", "start"], ["Cháu chào cô, cháu về ạ.", END]],
			},
		},
	},
}


## Lỗi trong kịch bản (thiếu nút START, nút không có câu / lựa chọn, lựa chọn trỏ tới nút
## không có). Rỗng = ổn.
static func problems() -> PackedStringArray:
	var found := PackedStringArray()
	for id: String in ALL:
		var nodes: Dictionary = ALL[id].get("nodes", {})
		if not nodes.has(START):
			found.append("%s: thiếu nút '%s'" % [id, START])
		for key: String in nodes:
			var node: Dictionary = nodes[key]
			var options: Array = node.get("options", [])
			if str(node.get("text", "")).is_empty():
				found.append("%s/%s: thiếu câu nói" % [id, key])
			if options.is_empty() or options.size() > MAX_OPTIONS:
				found.append("%s/%s: cần 1..%d lựa chọn" % [id, key, MAX_OPTIONS])
			for option: Array in options:
				var next: String = option[1]
				if next != END and not nodes.has(next):
					found.append("%s/%s: lựa chọn trỏ tới nút không có '%s'" % [id, key, next])
	return found
