import '../models/travel_spot.dart';

const daejeonCenterLat = 36.3504;
const daejeonCenterLng = 127.3845;

const daejeonSpots = <TravelSpot>[
  TravelSpot(
    id: 'ss',
    nameKo: '성심당 본점',
    city: 'Daejeon',
    lat: 36.3273, lng: 127.4275,
    env: {EnvTag.indoor},
    cat: {CatTag.food},
  ),
  TravelSpot(
    id: 'dma',
    nameKo: '대전시립미술관',
    city: 'Daejeon',
    lat: 36.3572, lng: 127.3865,
    env: {EnvTag.indoor},
    cat: {CatTag.culture},
  ),
  TravelSpot(
    id: 'nsm',
    nameKo: '국립중앙과학관',
    city: 'Daejeon',
    lat: 36.3722, lng: 127.3820,
    env: {EnvTag.indoor},
    cat: {CatTag.kids, CatTag.culture},
  ),
  TravelSpot(
    id: 'expo',
    nameKo: '엑스포과학공원',
    city: 'Daejeon',
    lat: 36.3684, lng: 127.3835,
    env: {EnvTag.outdoor},
    cat: {CatTag.culture, CatTag.nature},
  ),
  TravelSpot(
    id: 'yuseong',
    nameKo: '유성온천',
    city: 'Daejeon',
    lat: 36.3532, lng: 127.3410,
    env: {EnvTag.indoor, EnvTag.outdoor},
    cat: {CatTag.night, CatTag.nature},
  ),
  TravelSpot(
    id: 'daejeon_cafe',
    nameKo: '대흥동 카페거리',
    city: 'Daejeon',
    lat: 36.3279, lng: 127.4279,
    env: {EnvTag.indoor},
    cat: {CatTag.cafe},
  ),
  TravelSpot(
    id: 'hanbat',
    nameKo: '한밭수목원',
    city: 'Daejeon',
    lat: 36.3665, lng: 127.3822,
    env: {EnvTag.outdoor},
    cat: {CatTag.nature},
  ),
  TravelSpot(
    id: 'skyroad',
    nameKo: '스카이로드',
    city: 'Daejeon',
    lat: 36.3270, lng: 127.4271,
    env: {EnvTag.outdoor},
    cat: {CatTag.shopping, CatTag.night},
  ),
  TravelSpot(
    id: 'bomunsan',
    nameKo: '보문산 전망대',
    city: 'Daejeon',
    lat: 36.2918, lng: 127.4161,
    env: {EnvTag.outdoor},
    cat: {CatTag.nature},
  ),
  TravelSpot(
    id: 'daecheong',
    nameKo: '대청호',
    city: 'Daejeon',
    lat: 36.3627, lng: 127.4820,
    env: {EnvTag.outdoor},
    cat: {CatTag.nature},
  ),
];
