import requests
import math
import pprint
import time
import random
from gpiozero import MotionSensor, BadPinFactory
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from collections import defaultdict

# credentials needed for authentication with firebase database
cred = credentials.Certificate(
    'C:\\Users\\mhsha\\PycharmProjects\\test\\travelassistant-6d397-firebase-adminsdk-91rk2-9105483838.json')
default_app = firebase_admin.initialize_app(cred, {
    'databaseURL': 'https://travelassistant-6d397.firebaseio.com/'
})

# Get a reference of authenticated user
ref = db.reference().child('a21qfJypcxP7USNXh5CcmsQkhPr2')

res = ref.get()['personalInfo']
user_distance = res['distance']
user_latitude = res['latitude']
user_longitude = res['longitude']
user_outdoorhr = res['outdoorHour']
# Print the retrieved user personal info from firebase
print(user_distance, user_latitude, user_longitude, user_outdoorhr)

# R is earth's radius in km
R = 6371


# teta is the bearing
def pos_starter(distance, latitude1, longitude1, teta):
    # δ angle
    g = distance / R
    lat1 = math.radians(float(latitude1))
    lon1 = math.radians(float(longitude1))
    lat2 = math.asin(math.sin(lat1) * math.cos(g) + math.cos(lat1) * math.sin(g) * math.cos(teta))
    latitude2 = math.degrees(lat2)
    lon2 = lon1 + math.atan2(math.sin(teta) * math.sin(g) * math.cos(lat1),
                             math.cos(g) - math.sin(lat1) * math.sin(lat2))
    longitude2 = math.degrees(lon2)
    return latitude2, longitude2


# Based on an initial geo location and bearing and distance it produces
# a new geo location
def pos_changer(distance, latitude1, longitude1, bearing):
    res = ()
    if bearing == 'N':
        res = pos_starter(distance, latitude1, longitude1, 0)
        return res
    if bearing == 'E':
        res = pos_starter(distance, latitude1, longitude1, 90)
        return res
    if bearing == 'S':
        res = pos_starter(distance, latitude1, longitude1, 180)
        return res
    if bearing == 'W':
        res = pos_starter(distance, latitude1, longitude1, 270)
        return res
    if bearing == 'H':
        res = pos_starter(0, latitude1, longitude1, 0)
        return res
    else:
        print("No result found")
        return res


# concatenation of strings
def str_join(*args):
    return ''.join(map(str, args))


# Users geo-location
lat = user_latitude
lon = user_longitude


# for testing purposes of api working correctly
# https://api.openweathermap.org/data/2.5/uvi?appid=097420aba0f87f5033fbb7a6b5755d6b&lat=-37.813532&lon=144.972501

# Fetching weather metrics and uv index information from openweather API
def get_geolocation_forecast(lat, lon, hours):
    index_forecast = math.floor(hours / 3) + 1
    # print("lat is : ", lat)
    # print("lon is : ", lon)
    url = str_join('http://api.openweathermap.org/data/2.5/forecast?lat=', lat, '&lon=', lon,
                   '&units=metric&mode=json&appid=097420aba0f87f5033fbb7a6b5755d6b')

    url_uv = str_join('http://api.openweathermap.org/data/2.5/uvi/forecast?lat=', lat, '&lon=', lon,
                      '&units=metric&mode=json&appid=097420aba0f87f5033fbb7a6b5755d6b')

    r_melbourne = requests.get(url)
    r_uv_melbourne = requests.get(url_uv)
    today_uv_index = r_uv_melbourne.json()[0]['value']
    # print("UV index request : ", today_uv_index)
    tmr_forecast_melbourne = r_melbourne.json()['list'][0:index_forecast]
    melbourne_dict = {}
    uvindex_dict = {}
    temp_dict = {}
    weatherCondition_dict = {}
    windSpeed_dict = {}
    melbourne_dict['UVindex'] = uvindex_dict
    melbourne_dict['temp'] = temp_dict
    melbourne_dict['weatherCondition'] = weatherCondition_dict
    melbourne_dict['windSpeed'] = windSpeed_dict
    for tmp in tmr_forecast_melbourne:
        key = tmp['dt_txt']
        temp = tmp['main']['temp']
        temp_dict[key] = temp
        precipitation = tmp['weather'][0]['description']
        weatherCondition_dict[key] = precipitation
        wind = tmp['wind']['speed']
        windSpeed_dict[key] = wind
        uv = today_uv_index
        uvindex_dict[key] = uv

    return melbourne_dict


# lat_des = pos_changer(5, lat, lon, 'N')[0]

# lon_des = pos_changer(5, lat, lon, 'N')[1]

###forecast data for firebase 8 items
# pprint.pprint(get_geolocation_forecast(lat, lon, 24))

# This method produce the furthest weather metrcis based on the distance and bearing of inputted geo-location
def get_compass_forecast(lat_user, lon_user, hours, distance, bearing):
    lat_des = pos_changer(distance, lat_user, lon_user, bearing)[0]
    lon_des = pos_changer(distance, lat_user, lon_user, bearing)[1]
    res = get_geolocation_forecast(lat_des, lon_des, hours)
    time_key = list(res['temp'].keys())[0]
    res_uvindex = res['UVindex'][time_key]
    res_temp = res['temp'][time_key]
    res_weatherCondition = res['weatherCondition'][time_key]
    res_windSpeed = res['windSpeed'][time_key]

    uvindex_dict = {}

    temp_dict = {}

    weatherCondition_dict = {}

    windSpeed_dict = {}

    result_dict = {}
    result_dict['UVindex'] = uvindex_dict
    result_dict['temp'] = temp_dict
    result_dict['weatherCondition'] = weatherCondition_dict
    result_dict['windSpeed'] = windSpeed_dict

    uvindex_dict[bearing.lower()] = res_uvindex
    temp_dict[bearing.lower()] = res_temp
    weatherCondition_dict[bearing.lower()] = res_weatherCondition
    windSpeed_dict[bearing.lower()] = res_windSpeed

    return result_dict


# Fetch weather metrics for all the directions of the compass
def firebase_compass_data():
    east = get_compass_forecast(lat, lon, 3, user_distance + 20, 'E')
    home = get_compass_forecast(lat, lon, 3, user_distance + 20, 'H')
    north = get_compass_forecast(lat, lon, 3, user_distance + 20, 'N')
    south = get_compass_forecast(lat, lon, 3, user_distance + 20, 'S')
    west = get_compass_forecast(lat, lon, 3, user_distance + 20, 'W')
    dd = defaultdict(list)

    for d in (east, home, north, south, west):  # you can list as many input dicts as you want here
        for key, value in d.items():
            dd[key].append(value)

    return dict(dd)


all_directions = firebase_compass_data()


# Converting the list of dictionaries to a single dictionary
def clean_data():
    uvIndex_values = all_directions['UVindex']
    result = {}
    for d in uvIndex_values:
        result.update(d)
    all_directions['UVindex'] = result
    temp_values = all_directions['temp']
    result = {}
    for d in temp_values:
        result.update(d)
    all_directions['temp'] = result
    weatherCondition_values = all_directions['weatherCondition']
    result = {}
    for d in weatherCondition_values:
        result.update(d)
    all_directions['weatherCondition'] = result
    windSpeed_values = all_directions['windSpeed']
    result = {}
    for d in windSpeed_values:
        result.update(d)
    all_directions['windSpeed'] = result

    return all_directions


def moreDirections_firebae(lat, lon, distance):
    index_forecast = 1
    url = str_join('http://api.openweathermap.org/data/2.5/forecast?lat=', lat, '&lon=', lon,
                   '&units=metric&mode=json&appid=097420aba0f87f5033fbb7a6b5755d6b')

    url_uv = str_join('http://api.openweathermap.org/data/2.5/uvi?lat=', lat, '&lon=', lon,
                      '&units=metric&mode=json&appid=097420aba0f87f5033fbb7a6b5755d6b')

    r_melbourne = requests.get(url)
    r_uv_melbourne = requests.get(url_uv)
    today_uv_index = r_uv_melbourne.json()['value'][0]
    # The next 3 hours forecast
    tmr_forecast_melbourne = r_melbourne.json()['list'][0]
    uvindex_dict = {}
    uvindex_dict['e'] = today_uv_index
    uvindex_dict['h'] = today_uv_index
    uvindex_dict['n'] = today_uv_index
    uvindex_dict['s'] = today_uv_index
    uvindex_dict['w'] = today_uv_index
    temp_dict = {}
    temp_dict['e'] = 0
    temp_dict['h'] = 0
    temp_dict['n'] = 0
    temp_dict['s'] = 0
    temp_dict['w'] = 0
    weatherCondition_dict = {}
    weatherCondition_dict['e'] = ""
    weatherCondition_dict['h'] = ""
    weatherCondition_dict['n'] = ""
    weatherCondition_dict['s'] = ""
    weatherCondition_dict['w'] = ""
    windSpeed_dict = {}
    windSpeed_dict['e'] = 0
    windSpeed_dict['h'] = 0
    windSpeed_dict['n'] = 0
    windSpeed_dict['s'] = 0
    windSpeed_dict['w'] = 0
    result_dict = {}
    result_dict['UVindex'] = uvindex_dict
    result_dict['temp'] = temp_dict
    result_dict['weatherCondition'] = weatherCondition_dict
    result_dict['windSpeed'] = windSpeed_dict

    return result_dict


# temperature sensor
def generator(initialTemp, tempRange):
    res = (round(random.uniform(initialTemp - tempRange, initialTemp + tempRange), 1))
    print(res)
    return res


###forecast data for firebase that includes 8 items in interval of 3 hours
forecast_firebase_data = get_geolocation_forecast(lat, lon, 23)
pprint.pprint(forecast_firebase_data)
# compass data for firebase moreDirections child
moreDirections_firebase_data = clean_data()

print(moreDirections_firebase_data)
ref_forecast = ref.child("forecast")
print("ref_forecaset is : ", ref_forecast.get())
ref_moreDirections = ref.child("moreDirections")

# Motion sensor Gpio on the raspberry pi
try:
    pir = MotionSensor(4)
except:
    print("couldn't find motion sensor")

while True:
    if pir.motion_detected:
        print('Motion detected')
        ref_forecast.update(forecast_firebase_data)
        ref_moreDirections.update(moreDirections_firebase_data)
        generator(22, 8)
        time.sleep(5)
    else:
        print('scanning...')
        time.sleep(1)
