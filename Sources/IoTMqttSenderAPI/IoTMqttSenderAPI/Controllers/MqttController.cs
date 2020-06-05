using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using IoTMqttSenderAPI.Models;
using Microsoft.Extensions.Primitives;
using Microsoft.Azure.Devices.Client;

// For more information on enabling MVC for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace IoTMqttSenderAPI.Controllers
{

    [ApiController]
    [Route("[controller]")]
    public class MqttController : Controller
    {

        [HttpGet]
        [Route("{id}")]
        public string GetValues(string id)
        {
            return id;
        }

        // POST api/values
        [HttpPost]
        [Route("api")]
        public async Task Post([FromBody] MqttMessage mqttMessage)
        {

            StringValues connString;
            var mqttMessageString = JsonConvert.SerializeObject(mqttMessage);
            Request.Headers.TryGetValue("conn", out connString);
            Console.WriteLine(connString.ToString());
            Console.WriteLine(mqttMessageString);

            await Task.Run(() =>
            {

                var dc = DeviceClient.CreateFromConnectionString(connString, TransportType.Mqtt);
                var msg = new Message(Encoding.UTF8.GetBytes(mqttMessageString));
                dc.SendEventAsync(msg);                
                Console.WriteLine("Sent");

            });

        }

    }
}
