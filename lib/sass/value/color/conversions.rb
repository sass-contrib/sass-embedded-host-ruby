# frozen_string_literal: true

module Sass
  module Value
    class Color
      # @see https:#www.w3.org/TR/css-color-4/#color-conversion-code.
      # @see https://github.com/sass/dart-sass/blob/main/lib/src/value/color/conversions.dart
      module Conversions
        # The D50 white point.
        D50 = [0.3457 / 0.3585, 1.00000, (1.0 - 0.3457 - 0.3585) / 0.3585].freeze

        # The transformation matrix for converting LMS colors to OKLab.
        #
        # Note that this can't be directly multiplied with {XYZ_D65_TO_LMS}; see Color
        # Level 4 spec for details on how to convert between XYZ and OKLab.
        LMS_TO_OKLAB = [
          0.2104542553, 0.7936177850, -0.0040720468,
          1.9779984951, -2.4285922050, 0.4505937099,
          0.0259040371, 0.7827717662, -0.8086757660
        ].freeze

        # The transformation matrix for converting OKLab colors to LMS.
        #
        # Note that this can't be directly multiplied with {LMS_TO_XYZ_D65}; see Color
        # Level 4 spec for details on how to convert between XYZ and OKLab.
        OKLAB_TO_LMS = [
          0.99999999845051981432, 0.396337792173767856780, 0.215803758060758803390,
          1.00000000888176077670, -0.105561342323656349400, -0.063854174771705903402,
          1.00000005467241091770, -0.089484182094965759684, -1.291485537864091739900
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to
        # linear-light display-p3.
        LINEAR_SRGB_TO_LINEAR_DISPLAY_P3 = [
          0.82246196871436230, 0.17753803128563775, 0.00000000000000000,
          0.03319419885096161, 0.96680580114903840, 0.00000000000000000,
          0.01708263072112003, 0.07239744066396346, 0.91051992861491650
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        #  linear-light srgb.
        LINEAR_DISPLAY_P3_TO_LINEAR_SRGB = [
          1.22494017628055980, -0.22494017628055996, 0.00000000000000000,
          -0.04205695470968816, 1.04205695470968800, 0.00000000000000000,
          -0.01963755459033443, -0.07863604555063188, 1.09827360014096630
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to
        # linear-light a98-rgb.
        LINEAR_SRGB_TO_LINEAR_A98_RGB = [
          0.71512560685562470, 0.28487439314437535, 0.00000000000000000,
          0.00000000000000000, 1.00000000000000000, 0.00000000000000000,
          0.00000000000000000, 0.04116194845011846, 0.95883805154988160
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to
        # linear-light srgb.
        LINEAR_A98_RGB_TO_LINEAR_SRGB = [
          1.39835574396077830, -0.39835574396077830, 0.00000000000000000,
          0.00000000000000000, 1.00000000000000000, 0.00000000000000000,
          0.00000000000000000, -0.04292898929447326, 1.04292898929447330
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to
        # linear-light rec2020.
        LINEAR_SRGB_TO_LINEAR_REC2020 = [
          0.62740389593469900, 0.32928303837788370, 0.04331306568741722,
          0.06909728935823208, 0.91954039507545870, 0.01136231556630917,
          0.01639143887515027, 0.08801330787722575, 0.89559525324762400
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to
        # linear-light srgb.
        LINEAR_REC2020_TO_LINEAR_SRGB = [
          1.66049100210843450, -0.58764113878854950, -0.07284986331988487,
          -0.12455047452159074, 1.13289989712596030, -0.00834942260436947,
          -0.01815076335490530, -0.10057889800800737, 1.11872966136291270
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to xyz.
        LINEAR_SRGB_TO_XYZ_D65 = [
          0.41239079926595950, 0.35758433938387796, 0.18048078840183430,
          0.21263900587151036, 0.71516867876775590, 0.07219231536073371,
          0.01933081871559185, 0.11919477979462598, 0.95053215224966060
        ].freeze

        # The transformation matrix for converting xyz colors to linear-light srgb.
        XYZ_D65_TO_LINEAR_SRGB = [
          3.24096994190452130, -1.53738317757009350, -0.49861076029300330,
          -0.96924363628087980, 1.87596750150772060, 0.04155505740717561,
          0.05563007969699360, -0.20397695888897657, 1.05697151424287860
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to lms.
        LINEAR_SRGB_TO_LMS = [
          0.41222147080000016, 0.53633253629999990, 0.05144599290000001,
          0.21190349820000007, 0.68069954509999990, 0.10739695660000000,
          0.08830246190000005, 0.28171883759999994, 0.62997870050000000
        ].freeze

        # The transformation matrix for converting lms colors to linear-light srgb.
        LMS_TO_LINEAR_SRGB = [
          4.07674166134799300, -3.30771159040819240, 0.23096992872942781,
          -1.26843800409217660, 2.60975740066337240, -0.34131939631021974,
          -0.00419608654183720, -0.70341861445944950, 1.70761470093094480
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to
        # linear-light prophoto-rgb.
        LINEAR_SRGB_TO_LINEAR_PROPHOTO_RGB = [
          0.52927697762261160, 0.33015450197849283, 0.14056852039889556,
          0.09836585954044917, 0.87347071290696180, 0.02816342755258900,
          0.01687534092138684, 0.11765941425612084, 0.86546524482249230
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # linear-light srgb.
        LINEAR_PROPHOTO_RGB_TO_LINEAR_SRGB = [
          2.03438084951699600, -0.72763578993413420, -0.30674505958286180,
          -0.22882573163305037, 1.23174254119010480, -0.00291680955705449,
          -0.00855882878391742, -0.15326670213803720, 1.16182553092195470
        ].freeze

        # The transformation matrix for converting linear-light srgb colors to xyz-d50.
        LINEAR_SRGB_TO_XYZ_D50 = [
          0.43606574687426936, 0.38515150959015960, 0.14307841996513868,
          0.22249317711056518, 0.71688701309448240, 0.06061980979495235,
          0.01392392146316939, 0.09708132423141015, 0.71409935681588070
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to linear-light srgb.
        XYZ_D50_TO_LINEAR_SRGB = [
          3.13413585290011780, -1.61738599801804200, -0.49066221791109754,
          -0.97879547655577770, 1.91625437739598840, 0.03344287339036693,
          0.07195539255794733, -0.22897675981518200, 1.40538603511311820
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        # linear-light a98-rgb.
        LINEAR_DISPLAY_P3_TO_LINEAR_A98_RGB = [
          0.86400513747404840, 0.13599486252595164, 0.00000000000000000,
          -0.04205695470968816, 1.04205695470968800, 0.00000000000000000,
          -0.02056038078232985, -0.03250613804550798, 1.05306651882783790
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to
        # linear-light display-p3.
        LINEAR_A98_RGB_TO_LINEAR_DISPLAY_P3 = [
          1.15009441814101840, -0.15009441814101834, 0.00000000000000000,
          0.04641729862941844, 0.95358270137058150, 0.00000000000000000,
          0.02388759479083904, 0.02650477632633013, 0.94960762888283080
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        # linear-light rec2020.
        LINEAR_DISPLAY_P3_TO_LINEAR_REC2020 = [
          0.75383303436172180, 0.19859736905261630, 0.04756959658566187,
          0.04574384896535833, 0.94177721981169350, 0.01247893122294812,
          -0.00121034035451832, 0.01760171730108989, 0.98360862305342840
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to
        # linear-light display-p3.
        LINEAR_REC2020_TO_LINEAR_DISPLAY_P3 = [
          1.34357825258433200, -0.28217967052613570, -0.06139858205819628,
          -0.06529745278911953, 1.07578791584857460, -0.01049046305945495,
          0.00282178726170095, -0.01959849452449406, 1.01677670726279310
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        # xyz.
        LINEAR_DISPLAY_P3_TO_XYZ_D65 = [
          0.48657094864821626, 0.26566769316909294, 0.19821728523436250,
          0.22897456406974884, 0.69173852183650620, 0.07928691409374500,
          0.00000000000000000, 0.04511338185890257, 1.04394436890097570
        ].freeze

        # The transformation matrix for converting xyz colors to linear-light
        # display-p3.
        XYZ_D65_TO_LINEAR_DISPLAY_P3 = [
          2.49349691194142450, -0.93138361791912360, -0.40271078445071684,
          -0.82948896956157490, 1.76266406031834680, 0.02362468584194359,
          0.03584583024378433, -0.07617238926804170, 0.95688452400768730
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        # lms.
        LINEAR_DISPLAY_P3_TO_LMS = [
          0.48137985442585490, 0.46211836973903553, 0.05650177583510960,
          0.22883194490233110, 0.65321681282840370, 0.11795124216926511,
          0.08394575573016760, 0.22416526885956980, 0.69188897541026260
        ].freeze

        # The transformation matrix for converting lms colors to linear-light
        # display-p3.
        LMS_TO_LINEAR_DISPLAY_P3 = [
          3.12776898667772140, -2.25713579553953770, 0.12936680863610234,
          -1.09100904738343900, 2.41333175827934370, -0.32232271065457110,
          -0.02601081320950207, -0.50804132569306730, 1.53405213885176520
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        # linear-light prophoto-rgb.
        LINEAR_DISPLAY_P3_TO_LINEAR_PROPHOTO_RGB = [
          0.63168691934035890, 0.21393038569465722, 0.15438269496498390,
          0.08320371426648458, 0.88586513676302430, 0.03093114897049121,
          -0.00127273456473881, 0.05075510433665735, 0.95051763022808140
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # linear-light display-p3.
        LINEAR_PROPHOTO_RGB_TO_LINEAR_DISPLAY_P3 = [
          1.63257560870691790, -0.37977161848259840, -0.25280399022431950,
          -0.15370040233755072, 1.16670254724250140, -0.01300214490495082,
          0.01039319529676572, -0.06280731264959440, 1.05241411735282870
        ].freeze

        # The transformation matrix for converting linear-light display-p3 colors to
        # xyz-d50.
        LINEAR_DISPLAY_P3_TO_XYZ_D50 = [
          0.51514644296811600, 0.29200998206385770, 0.15713925139759397,
          0.24120032212525520, 0.69222254113138180, 0.06657713674336294,
          -0.00105013914714014, 0.04187827018907460, 0.78427647146852570
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to linear-light
        # display-p3.
        XYZ_D50_TO_LINEAR_DISPLAY_P3 = [
          2.40393412185549730, -0.99003044249559310, -0.39761363181465614,
          -0.84227001614546880, 1.79895801610670820, 0.01604562477090472,
          0.04819381686413303, -0.09738519815446048, 1.27367136933212730
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to
        # linear-light rec2020.
        LINEAR_A98_RGB_TO_LINEAR_REC2020 = [
          0.87733384166365680, 0.07749370651571998, 0.04517245182062317,
          0.09662259146620378, 0.89152732024418050, 0.01185008828961569,
          0.02292106270284839, 0.04303668501067932, 0.93404225228647230
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to
        # linear-light a98-rgb.
        LINEAR_REC2020_TO_LINEAR_A98_RGB = [
          1.15197839471591630, -0.09750305530240860, -0.05447533941350766,
          -0.12455047452159074, 1.13289989712596030, -0.00834942260436947,
          -0.02253038278105590, -0.04980650742838876, 1.07233689020944460
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to xyz.
        LINEAR_A98_RGB_TO_XYZ_D65 = [
          0.57666904291013080, 0.18555823790654627, 0.18822864623499472,
          0.29734497525053616, 0.62736356625546600, 0.07529145849399789,
          0.02703136138641237, 0.07068885253582714, 0.99133753683763890
        ].freeze

        # The transformation matrix for converting xyz colors to linear-light a98-rgb.
        XYZ_D65_TO_LINEAR_A98_RGB = [
          2.04158790381074600, -0.56500697427885960, -0.34473135077832950,
          -0.96924363628087980, 1.87596750150772060, 0.04155505740717561,
          0.01344428063203102, -0.11836239223101823, 1.01517499439120540
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to lms.
        LINEAR_A98_RGB_TO_LMS = [
          0.57643226147714040, 0.36991322114441194, 0.05365451737844765,
          0.29631647387335260, 0.59167612662650690, 0.11200739940014041,
          0.12347825480374285, 0.21949869580674647, 0.65702304938951070
        ].freeze

        # The transformation matrix for converting lms colors to linear-light a98-rgb.
        LMS_TO_LINEAR_A98_RGB = [
          2.55403684790806950, -1.62197620262602140, 0.06793935455575403,
          -1.26843800409217660, 2.60975740066337240, -0.34131939631021974,
          -0.05623474718052319, -0.56704183411879500, 1.62327658124261400
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to
        # linear-light prophoto-rgb.
        LINEAR_A98_RGB_TO_LINEAR_PROPHOTO_RGB = [
          0.74011750180477920, 0.11327951328898105, 0.14660298490623970,
          0.13755046469802620, 0.83307708026948400, 0.02937245503248977,
          0.02359772990871766, 0.07378347703906656, 0.90261879305221580
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # linear-light a98-rgb.
        LINEAR_PROPHOTO_RGB_TO_LINEAR_A98_RGB = [
          1.38965124815152000, -0.16945907691487766, -0.22019217123664242,
          -0.22882573163305037, 1.23174254119010480, -0.00291680955705449,
          -0.01762544368426068, -0.09625702306122665, 1.11388246674548740
        ].freeze

        # The transformation matrix for converting linear-light a98-rgb colors to
        # xyz-d50.
        LINEAR_A98_RGB_TO_XYZ_D50 = [
          0.60977504188618140, 0.20530000261929401, 0.14922063192409227,
          0.31112461220464155, 0.62565323083468560, 0.06322215696067286,
          0.01947059555648168, 0.06087908649415867, 0.74475492045981980
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to linear-light
        # a98-rgb.
        XYZ_D50_TO_LINEAR_A98_RGB = [
          1.96246703637688060, -0.61074234048150730, -0.34135809808271540,
          -0.97879547655577770, 1.91625437739598840, 0.03344287339036693,
          0.02870443944957101, -0.14067486633170680, 1.34891418141379370
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to xyz.
        LINEAR_REC2020_TO_XYZ_D65 = [
          0.63695804830129130, 0.14461690358620838, 0.16888097516417205,
          0.26270021201126703, 0.67799807151887100, 0.05930171646986194,
          0.00000000000000000, 0.02807269304908750, 1.06098505771079090
        ].freeze

        # The transformation matrix for converting xyz colors to linear-light rec2020.
        XYZ_D65_TO_LINEAR_REC2020 = [
          1.71665118797126760, -0.35567078377639240, -0.25336628137365980,
          -0.66668435183248900, 1.61648123663493900, 0.01576854581391113,
          0.01763985744531091, -0.04277061325780865, 0.94210312123547400
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to lms.
        LINEAR_REC2020_TO_LMS = [
          0.61675578719908560, 0.36019839939276255, 0.02304581340815186,
          0.26513306398328140, 0.63583936407771060, 0.09902757183900800,
          0.10010263423281572, 0.20390651940192997, 0.69599084636525430
        ].freeze

        # The transformation matrix for converting lms colors to linear-light rec2020.
        LMS_TO_LINEAR_REC2020 = [
          2.13990673569556170, -1.24638950878469060, 0.10648277296448995,
          -0.88473586245815630, 2.16323098210838260, -0.27849511943390290,
          -0.04857375801465988, -0.45450314291725170, 1.50307690088646130
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to
        # linear-light prophoto-rgb.
        LINEAR_REC2020_TO_LINEAR_PROPHOTO_RGB = [
          0.83518733312972350, 0.04886884858605698, 0.11594381828421951,
          0.05403324519953363, 0.92891840856920440, 0.01704834623126199,
          -0.00234203897072539, 0.03633215316169465, 0.96600988580903070
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # linear-light rec2020.
        LINEAR_PROPHOTO_RGB_TO_LINEAR_REC2020 = [
          1.20065932951740800, -0.05756805370122346, -0.14309127581618444,
          -0.06994154955888504, 1.08061789759721400, -0.01067634803832895,
          0.00554147334294746, -0.04078219298657951, 1.03524071964363200
        ].freeze

        # The transformation matrix for converting linear-light rec2020 colors to
        # xyz-d50.
        LINEAR_REC2020_TO_XYZ_D50 = [
          0.67351546318827600, 0.16569726370390453, 0.12508294953738705,
          0.27905900514112060, 0.67531800574910980, 0.04562298910976962,
          -0.00193242713400438, 0.02997782679282923, 0.79705920285163550
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to linear-light
        # rec2020.
        XYZ_D50_TO_LINEAR_REC2020 = [
          1.64718490467176600, -0.39368189813164710, -0.23595963848828266,
          -0.68266410741738180, 1.64771461274440760, 0.01281708338512084,
          0.02966887665275675, -0.06292589642970030, 1.25355782018657710
        ].freeze

        # The transformation matrix for converting xyz colors to lms.
        XYZ_D65_TO_LMS = [
          0.81902244321643190, 0.36190625628012210, -0.12887378261216414,
          0.03298366719802710, 0.92928684689655460, 0.03614466816999844,
          0.04817719956604625, 0.26423952494422764, 0.63354782581369370
        ].freeze

        # The transformation matrix for converting lms colors to xyz.
        LMS_TO_XYZ_D65 = [
          1.22687987337415570, -0.55781499655548140, 0.28139105017721590,
          -0.04057576262431372, 1.11228682939705960, -0.07171106666151703,
          -0.07637294974672143, -0.42149332396279143, 1.58692402442724180
        ].freeze

        # The transformation matrix for converting xyz colors to linear-light
        # prophoto-rgb.
        XYZ_D65_TO_LINEAR_PROPHOTO_RGB = [
          1.40319046337749790, -0.22301514479051668, -0.10160668507413790,
          -0.52623840216330720, 1.48163196292346440, 0.01701879027252688,
          -0.01120226528622150, 0.01824640347962099, 0.91124722749150480
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # xyz.
        LINEAR_PROPHOTO_RGB_TO_XYZ_D65 = [
          0.75559074229692100, 0.11271984265940525, 0.08214534209534540,
          0.26832184357857190, 0.71511525666179120, 0.01656289975963685,
          0.00391597276242580, -0.01293344283684181, 1.09807522083429450
        ].freeze

        # The transformation matrix for converting xyz colors to xyz-d50.
        XYZ_D65_TO_XYZ_D50 = [
          1.04792979254499660, 0.02294687060160952, -0.05019226628920519,
          0.02962780877005567, 0.99043442675388000, -0.01707379906341879,
          -0.00924304064620452, 0.01505519149029816, 0.75187428142813700
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to xyz.
        XYZ_D50_TO_XYZ_D65 = [
          0.95547342148807520, -0.02309845494876452, 0.06325924320057065,
          -0.02836970933386358, 1.00999539808130410, 0.02104144119191730,
          0.01231401486448199, -0.02050764929889898, 1.33036592624212400
        ].freeze

        # The transformation matrix for converting lms colors to linear-light
        # prophoto-rgb.
        LMS_TO_LINEAR_PROPHOTO_RGB = [
          1.73835514985815240, -0.98795095237343430, 0.24959580241648663,
          -0.70704942624914860, 1.93437008438177620, -0.22732065793919040,
          -0.08407883426424761, -0.35754059702097796, 1.44161943124947150
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # lms.
        LINEAR_PROPHOTO_RGB_TO_LMS = [
          0.71544846349294310, 0.35279154798172740, -0.06824001147467047,
          0.27441165509049420, 0.66779764080811480, 0.05779070400139092,
          0.10978443849083751, 0.18619828746596980, 0.70401727404319270
        ].freeze

        # The transformation matrix for converting lms colors to xyz-d50.
        LMS_TO_XYZ_D50 = [
          1.28858621583908840, -0.53787174651736210, 0.21358120705405403,
          -0.00253389352489796, 1.09231682453266550, -0.08978293089853581,
          -0.06937383312514489, -0.29500839218634667, 1.18948682779245090
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to lms.
        XYZ_D50_TO_LMS = [
          0.77070004712402500, 0.34924839871072740, -0.11202352004249890,
          0.00559650559780223, 0.93707232493333150, 0.06972569131301698,
          0.04633715253432816, 0.25277530868525870, 0.85145807371608350
        ].freeze

        # The transformation matrix for converting linear-light prophoto-rgb colors to
        # xyz-d50.
        LINEAR_PROPHOTO_RGB_TO_XYZ_D50 = [
          0.79776664490064230, 0.13518129740053308, 0.03134773412839220,
          0.28807482881940130, 0.71183523424187300, 0.00008993693872564,
          0.00000000000000000, 0.00000000000000000, 0.82510460251046020
        ].freeze

        # The transformation matrix for converting xyz-d50 colors to linear-light
        # prophoto-rgb.
        XYZ_D50_TO_LINEAR_PROPHOTO_RGB = [
          1.34578688164715830, -0.25557208737979464, -0.05110186497554526,
          -0.54463070512490190, 1.50824774284514680, 0.02052744743642139,
          0.00000000000000000, 0.00000000000000000, 1.21196754563894520
        ].freeze
      end

      private_constant :Conversions
    end
  end
end
